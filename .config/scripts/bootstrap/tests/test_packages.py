#!/usr/bin/env python3
"""Exercise committed manifest selection, build isolation and restore failures."""
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

BOOTSTRAP = Path(__file__).resolve().parents[1]


class PackageRestoreTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.repo = self.root / "repo"
        self.repo.mkdir()
        self.env = dict(os.environ, GIT_CONFIG_GLOBAL="/dev/null", GIT_CONFIG_NOSYSTEM="1", LC_ALL="C")
        self.git("init", "--quiet")
        self.manifests = self.repo / ".config/archiso-backup"
        self.manifests.mkdir(parents=True)
        for name, text in {
            "pkglistPacmanInstalled.txt": "base\nextra-app\n",
            "foreignpkglist.txt": "awesome-luajit-git\nforeign-extra\n",
            "pkglistAll.txt": "awesome-luajit-git\nbase\nextra-app\nforeign-extra\n",
            "pkglistMinimal.txt": "awesome-luajit-git\nbase\nexplicit-runtime\n",
        }.items():
            (self.manifests / name).write_text(text)
        self.commit()
        self.destination = self.root / "selected"
        self.destination.mkdir()

    def git(self, *args):
        return subprocess.run(["git", "-C", str(self.repo), *args], env=self.env,
                              check=True, text=True, capture_output=True)

    def commit(self):
        self.git("add", ".")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.invalid",
                 "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "fixtures")

    def shell(self, code, *args):
        prelude = 'log_fail() { printf "%s\\n" "$*" >&2; }; source "$1/packages.sh"; shift; '
        return subprocess.run(["bash", "-c", prelude + code, "test", str(BOOTSTRAP), *map(str, args)],
                              check=False, env=self.env, text=True, capture_output=True)

    def select(self, profile):
        return self.shell('pacman() { [[ "$1" == -Si && "$2" == explicit-runtime ]]; }; '
                          'load_package_manifests "$1" "$2" "$3"', self.repo / ".git",
                          self.destination, profile)

    def selected(self, name):
        return (self.destination / name).read_text().splitlines()

    def test_full_profile_retains_committed_manifests(self):
        self.assertEqual(self.select("full").returncode, 0)
        self.assertEqual(self.selected("pkglistPacmanInstalled.txt"), ["base", "extra-app"])
        self.assertEqual(self.selected("foreignpkglist.txt"), ["awesome-luajit-git", "foreign-extra"])

    def test_minimal_partitions_foreign_and_explicit_runtime_dependencies(self):
        result = self.select("minimal")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.selected("pkglistPacmanInstalled.txt"), ["base", "explicit-runtime"])
        self.assertEqual(self.selected("foreignpkglist.txt"), ["awesome-luajit-git"])
        self.assertEqual(self.selected("pkglistAll.txt"), ["awesome-luajit-git", "base", "explicit-runtime"])

    def test_generated_working_manifests_are_not_restore_input(self):
        (self.manifests / "pkglistMinimal.txt").write_text("wrong-working-copy\n")
        self.assertEqual(self.select("minimal").returncode, 0)
        self.assertNotIn("wrong-working-copy", self.selected("pkglistAll.txt"))

    def test_minimal_only_custom_package_is_not_assumed_to_be_official(self):
        (self.manifests / "pkglistMinimal.txt").write_text("base\ncustom-driver\nexplicit-runtime\n")
        self.commit()
        result = self.select("minimal")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.selected("pkglistPacmanInstalled.txt"), ["base", "explicit-runtime"])
        self.assertEqual(self.selected("foreignpkglist.txt"), ["custom-driver"])

    def test_disagreeing_full_manifests_fail(self):
        (self.manifests / "pkglistAll.txt").write_text("base\n")
        self.commit()
        self.assertNotEqual(self.select("full").returncode, 0)

    def test_missing_minimal_manifest_fails(self):
        (self.manifests / "pkglistMinimal.txt").unlink()
        self.commit()
        self.assertNotEqual(self.select("minimal").returncode, 0)

    def test_empty_or_invalid_minimal_manifest_fails(self):
        for text in ("", "base --unwanted-option\n"):
            with self.subTest(text=text):
                (self.manifests / "pkglistMinimal.txt").write_text(text)
                self.commit()
                self.assertNotEqual(self.select("minimal").returncode, 0)

    def test_invalid_profile_fails(self):
        self.assertNotEqual(self.select("mistyped").returncode, 0)

    def test_account_templates_use_installing_user_and_home(self):
        source = self.root / "account.conf"
        destination = self.root / "rendered.conf"
        source.write_text('AllowUsers ragu\nUser=ragu\nuser = "ragu"\nExecStart=/home/ragu/lock\nPermitRootLogin no\n')
        result = self.shell('source "$1/lib.sh"; id() { printf "bangari\\n"; }; '
                            'HOME=/home/bangari; render_user_config "$2" "$3"',
                            BOOTSTRAP, source, destination)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(destination.read_text(),
                         'AllowUsers bangari\nUser=bangari\nuser = "bangari"\n'
                         'ExecStart=/home/bangari/lock\nPermitRootLogin no\n')

    def test_arch_build_environment_overrides_homebrew(self):
        self.env.update(PATH="/home/linuxbrew/.linuxbrew/bin:" + os.environ["PATH"],
                        PKG_CONFIG="brew-pkg-config", PKG_CONFIG_LIBDIR="/brew/lib/pkgconfig")
        result = self.shell('arch_package_command /bin/bash -c '\
                            "'printf \"%s\\n\" \"$PATH\" \"$PKG_CONFIG\" \"$PKG_CONFIG_LIBDIR\" \"$_BUILD_DOCS\"'")
        self.assertEqual(result.returncode, 0, result.stderr)
        lines = result.stdout.splitlines()
        self.assertTrue(lines[0].startswith("/usr/bin:/bin:"))
        self.assertEqual(lines[1:], ["/usr/bin/pkg-config", "/usr/lib/pkgconfig:/usr/share/pkgconfig", "0"])

    def test_missing_packages_fail_verification(self):
        self.assertEqual(self.select("minimal").returncode, 0)
        result = self.shell('pacman() { printf "awesome-luajit-git\\nexplicit-runtime\\n"; return 127; }; '
                            'verify_package_restore "$1" "$2"',
                            self.destination / "pkglistAll.txt", self.destination)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("explicit-runtime", result.stderr)

    def test_dependency_packages_do_not_count_as_profile_mismatches(self):
        self.assertEqual(self.select("minimal").returncode, 0)
        result = self.shell('pacman() { [[ "$1" == -T ]]; }; '
                            'verify_package_restore "$1" "$2"', self.destination / "pkglistAll.txt", self.destination)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_provider_is_verified_as_a_dependency_not_an_installed_name(self):
        desired = self.destination / "virtual.txt"
        desired.write_text("virtual-audio\n")
        result = self.shell('pacman() { [[ "$1" == -T && "$2" == virtual-audio ]]; }; '
                            'verify_package_restore "$1" "$2"', desired, self.destination)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_pruning_retains_the_actual_package_providing_a_selected_dependency(self):
        desired = self.destination / "virtual.txt"
        desired.write_text("virtual-audio\n")
        output = self.destination / "resolved.txt"
        result = self.shell('pacman() { [[ "$1" == -Qq && "$2" == virtual-audio ]] || return 1; '
                            'printf "driver-bundle\\n"; }; resolve_package_selection "$1" "$2"', desired, output)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(output.read_text(), "driver-bundle\n")

    def test_failed_installed_database_query_fails_verification(self):
        self.assertEqual(self.select("full").returncode, 0)
        result = self.shell('pacman() { return 1; }; verify_package_restore "$1" "$2"',
                            self.destination / "pkglistAll.txt", self.destination)
        self.assertNotEqual(result.returncode, 0)

    def package_step(self, scenario, *, existing_npm_path=False):
        """Run the real package step with package managers replaced by functions."""
        home = self.root / "home"
        home.mkdir()
        (home / ".config.git").symlink_to(self.repo / ".git")
        (home / ".omo").mkdir()
        (home / ".omo/omo.terra.jsonc").write_text("{}\n")
        tool = home / ".local/bin/topgrade"
        tool.parent.mkdir(parents=True)
        tool.write_text('#!/bin/bash\nprintf "%s\\n" "$PATH" > "$HOME/profile-installer-path"\n')
        tool.chmod(0o755)
        key = self.repo / ".git/git-crypt/keys/default"
        key.parent.mkdir(parents=True)
        key.write_text("synthetic-unlock-marker\n")
        self.git("config", "filter.git-crypt.smudge", "git-crypt smudge")
        self.env.update(HOME=str(home), SHELL="/bin/zsh", SCENARIO=scenario,
                        PACKAGE_PROFILE="full", PRUNE_PACKAGES="true",
                        XDG_DATA_HOME=str(home / ".local/share"),
                        XDG_CONFIG_HOME=str(home / ".config"), GNUPGHOME=str(home / ".config/gnupg"))
        if existing_npm_path:
            self.env["PATH"] = str(home / ".local/share/npm/bin") + ":" + self.env["PATH"]
        harness = r'''
set -euo pipefail
source "$1/lib.sh"
REMINDERS=()
require_package() { :; }
gpg() { printf 'sec:synthetic\n'; }
git-crypt() { printf 'unexpected unlock\n' >&2; return 1; }
brew() { return 0; }
# The wrapper's real environment is tested separately. Dispatch only to these
# shell functions, never to an installed pacman or paru on the test host.
env() { while [[ "$1" == *=* ]]; do shift; done; "$@"; }
sudo() {
    case "$1" in
        touch|rm) return 0 ;;
        pacman) shift; pacman "$@" ;;
        *) printf 'unexpected sudo command\n' >&2; return 1 ;;
    esac
}
pacman() {
    printf '%s\n' "pacman $*" >> "$HOME/trace"
    case "$1" in
        -Syu) [[ "$SCENARIO" != official-failure ]] ;;
        -Q)
            [[ "$2" == awesome-luajit-git || "$SCENARIO" == installed ]]
            ;;
        -T)
            [[ "$SCENARIO" != installed ]] || return 0
            printf 'foreign-extra\n'
            return 127
            ;;
        -Qq|-Qqe)
            printf 'base\nextra-app\nawesome-luajit-git\n'
            [[ "$SCENARIO" != installed ]] || printf 'foreign-extra\n'
            return 0
            ;;
        -D) return 0 ;;
        *) printf 'unexpected pacman command\n' >&2; return 1 ;;
    esac
}
paru() {
    printf '%s\n' "paru $*" >> "$HOME/trace"
    [[ "$1" != -S || "$SCENARIO" != aur-failure ]]
}
prompt_yn() { printf 'prune reached\n' >> "$HOME/trace"; return 1; }
source "$1/01-packages.sh"
printf '%s\n' "$PATH" > "$HOME/bootstrap-parent-path"
'''
        result = subprocess.run(["bash", "-c", harness, "test", str(BOOTSTRAP)], check=False, env=self.env,
                                text=True, capture_output=True)
        trace = (home / "trace").read_text() if (home / "trace").exists() else ""
        return result, trace

    def test_official_failure_stops_before_aur_and_pruning(self):
        result, trace = self.package_step("official-failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Official package restore failed", result.stdout)
        self.assertNotIn("paru -S --needed", trace)
        self.assertNotIn("prune reached", trace)

    def test_aur_failure_stops_before_pruning(self):
        result, trace = self.package_step("aur-failure")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("AUR package restore failed", result.stdout)
        self.assertNotIn("prune reached", trace)
        self.assertNotIn("paru -S --needed awesome-luajit-git", trace)

    def test_successful_installer_cannot_hide_a_missing_package(self):
        result, trace = self.package_step("silent-missing")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Selected package profile is incomplete", result.stdout)
        self.assertNotIn("prune reached", trace)

    def test_already_installed_aur_packages_are_not_rebuilt(self):
        result, trace = self.package_step("installed")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertNotIn("paru -S --needed", trace)
        self.assertIn("Already installed: awesome-luajit-git", result.stdout)
        self.assertNotIn("unexpected unlock", result.stderr)
        path = (self.root / "home/profile-installer-path").read_text()
        self.assertIn(str(self.root / "home/.local/share/npm/bin"), path)
        parent_path = (self.root / "home/bootstrap-parent-path").read_text()
        self.assertNotIn(str(self.root / "home/.local/share/npm/bin"), parent_path)

    def test_bootstrap_retains_existing_npm_path_without_duplication(self):
        result, _ = self.package_step("installed", existing_npm_path=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        path = (self.root / "home/profile-installer-path").read_text().strip()
        self.assertEqual(path.split(":").count(str(self.root / "home/.local/share/npm/bin")), 1)


if __name__ == "__main__":
    unittest.main()
