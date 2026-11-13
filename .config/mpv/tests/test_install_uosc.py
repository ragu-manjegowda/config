#!/usr/bin/env python3
"""Exercise release installation and updates using local assets and a fake curl."""

import hashlib
import json
import os
import platform
import shutil
import stat
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path

INSTALLER = Path(__file__).resolve().parents[1] / "install-uosc.sh"


class InstallUoscTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.mpv = self.root / "mpv config"
        self.mpv.mkdir()
        self.installer = self.mpv / "install-uosc.sh"
        shutil.copyfile(INSTALLER, self.installer)
        self.fixture = self.root / "assets"
        self.fixture.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.requests = self.root / "requests"
        curl = self.bin / "curl"
        curl.write_text("""#!/usr/bin/env python3
import os
import shutil
import sys
from pathlib import Path
from urllib.parse import urlsplit
arguments = sys.argv[1:]
name = urlsplit(arguments[-1]).path.rsplit('/', 1)[-1]
fixture = Path(os.environ['UOSC_FIXTURE'])
with Path(os.environ['UOSC_REQUESTS']).open('a') as requests:
    requests.write(name + '\\n')
if name == os.environ.get('UOSC_FAIL_DOWNLOAD'):
    sys.exit(22)
source = fixture / ('release.json' if name == 'latest' else name)
shutil.copyfile(source, arguments[arguments.index('--output') + 1])
""")
        curl.chmod(0o755)
        self.environment = dict(
            os.environ,
            PATH=f"{self.bin}:/usr/bin:/bin",
            UOSC_FIXTURE=str(self.fixture),
            UOSC_REQUESTS=str(self.requests),
        )
        self.runtime = self.mpv / "scripts/uosc"
        self.helper = (
            "bin/ziggy-darwin" if platform.system() == "Darwin" else "bin/ziggy-linux"
        )
        self.configuration = self.mpv / "script-opts/uosc.conf"
        self.release("5.13.0")

    def release(self, version, extra_files=None):
        files = {
            "scripts/uosc/main.lua": f"local uosc_version = '{version}'\n",
            "scripts/uosc/bin/ziggy-linux": "native helper",
            "scripts/uosc/bin/ziggy-darwin": "native helper",
            "fonts/uosc_icons.otf": "icons " + version,
            "fonts/uosc_textures.ttf": "textures " + version,
        }
        files.update(extra_files or {})
        with zipfile.ZipFile(self.fixture / "uosc.zip", "w") as archive:
            for name, text in files.items():
                archive.writestr(name, text)
        (self.fixture / "uosc.conf").write_text("upstream defaults " + version)
        assets = []
        for name in ("uosc.zip", "uosc.conf"):
            digest = hashlib.sha256((self.fixture / name).read_bytes()).hexdigest()
            assets.append(
                {
                    "name": name,
                    "digest": "sha256:" + digest,
                    "browser_download_url": f"https://github.com/tomasklaen/uosc/releases/download/{version}/{name}",
                }
            )
        self.metadata = {
            "tag_name": version,
            "draft": False,
            "prerelease": False,
            "assets": assets,
        }
        self.write_metadata()

    def write_metadata(self):
        (self.fixture / "release.json").write_text(json.dumps(self.metadata))

    def install(self, *arguments):
        return subprocess.run(
            ["/bin/bash", str(self.installer), *arguments],
            env=self.environment,
            cwd=self.root,
            text=True,
            capture_output=True,
        )

    def assert_success(self):
        result = self.install()
        self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def assert_failure(self, expected):
        result = self.install()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(expected, result.stderr)
        return result

    def test_fresh_install(self):
        self.assert_success()
        self.assertEqual((self.runtime / ".release-version").read_text(), "5.13.0\n")
        self.assertTrue(os.access(self.runtime / self.helper, os.X_OK))
        self.assertEqual(self.configuration.read_text(), "upstream defaults 5.13.0")
        self.assertEqual(
            (self.mpv / "fonts/uosc_icons.otf").read_text(), "icons 5.13.0"
        )

    def test_repeated_install_only_fetches_metadata(self):
        self.assert_success()
        self.requests.write_text("")
        result = self.assert_success()
        self.assertIn("no update needed", result.stdout)
        self.assertEqual(self.requests.read_text(), "latest\n")

    def test_update_preserves_settings_and_unrelated_files(self):
        self.assert_success()
        self.configuration.write_text("custom settings")
        (self.runtime / "obsolete.lua").touch()
        unrelated = [
            self.mpv / "fonts/other.ttf",
            self.mpv / "scripts/other.lua",
            self.mpv / "mpv.conf",
            self.mpv / "input.conf",
        ]
        for destination in unrelated:
            destination.write_text("preserved")
        self.release("5.14.0")
        self.requests.write_text("")
        self.assert_success()
        self.assertEqual((self.runtime / ".release-version").read_text(), "5.14.0\n")
        self.assertFalse((self.runtime / "obsolete.lua").exists())
        self.assertEqual(self.configuration.read_text(), "custom settings")
        self.assertNotIn("uosc.conf", self.requests.read_text())
        for destination in unrelated:
            self.assertEqual(destination.read_text(), "preserved")

    def test_missing_font_repairs_current_release(self):
        self.assert_success()
        (self.mpv / "fonts/uosc_icons.otf").unlink()
        self.assert_success()
        self.assertTrue((self.mpv / "fonts/uosc_icons.otf").is_file())

    def test_missing_configuration_restores_defaults(self):
        self.assert_success()
        self.configuration.unlink()
        self.assert_success()
        self.assertEqual(self.configuration.read_text(), "upstream defaults 5.13.0")

    def test_nonexecutable_helper_is_repaired(self):
        self.assert_success()
        (self.runtime / self.helper).chmod(0o644)
        self.assert_success()
        self.assertTrue(os.access(self.runtime / self.helper, os.X_OK))

    def test_download_failure_preserves_installation(self):
        self.assert_success()
        self.release("5.14.0")
        self.environment["UOSC_FAIL_DOWNLOAD"] = "uosc.zip"
        self.assert_failure("non-zero exit status")
        self.assertEqual((self.runtime / ".release-version").read_text(), "5.13.0\n")

    def test_checksum_failure_preserves_installation(self):
        self.assert_success()
        self.release("5.14.0")
        (self.fixture / "uosc.zip").write_bytes(b"corrupt archive")
        self.assert_failure("Checksum verification failed")
        self.assertEqual((self.runtime / ".release-version").read_text(), "5.13.0\n")

    def test_unsafe_archive_path_is_rejected(self):
        self.release("5.13.0", {"../escaped": "unsafe"})
        self.assert_failure("unsafe path")
        self.assertFalse(self.runtime.exists())

    def test_symbolic_link_archive_entry_is_rejected(self):
        info = zipfile.ZipInfo("scripts/uosc/link")
        info.create_system = 3
        info.external_attr = (stat.S_IFLNK | 0o777) << 16
        with zipfile.ZipFile(self.fixture / "uosc.zip", "a") as archive:
            archive.writestr(info, "outside")
        self.metadata["assets"][0]["digest"] = (
            "sha256:"
            + hashlib.sha256((self.fixture / "uosc.zip").read_bytes()).hexdigest()
        )
        self.write_metadata()
        self.assert_failure("symbolic link")

    def test_runtime_symlink_is_not_replaced(self):
        self.runtime.parent.mkdir()
        self.runtime.symlink_to(self.fixture, target_is_directory=True)
        self.assert_failure("Refusing to replace")
        self.assertTrue(self.runtime.is_symlink())

    def test_unrecognized_runtime_directory_is_not_replaced(self):
        self.runtime.mkdir(parents=True)
        (self.runtime / "unrelated.txt").write_text("keep")
        self.assert_failure("not a recognizable uosc installation")
        self.assertEqual((self.runtime / "unrelated.txt").read_text(), "keep")

    def test_missing_asset_is_rejected(self):
        self.metadata["assets"] = []
        self.write_metadata()
        self.assert_failure("missing uosc.zip")

    def test_prerelease_is_rejected(self):
        self.metadata["prerelease"] = True
        self.write_metadata()
        self.assert_failure("did not return a stable release")

    def test_foreign_asset_host_is_rejected(self):
        self.metadata["assets"][0]["browser_download_url"] = (
            "https://example.com/uosc.zip"
        )
        self.write_metadata()
        self.assert_failure("not hosted in the official uosc repository")

    def test_wrong_archived_version_is_rejected(self):
        self.metadata["tag_name"] = "5.14.0"
        self.write_metadata()
        self.assert_failure("does not match the release tag")

    def test_replacement_failure_rolls_back(self):
        self.assert_success()
        (self.mpv / "fonts/uosc_icons.otf").unlink()
        (self.mpv / "fonts/uosc_textures.ttf").unlink()
        (self.mpv / "fonts").rmdir()
        (self.mpv / "fonts").write_text("conflict")
        self.release("5.14.0")
        self.assert_failure("File exists")
        self.assertEqual((self.runtime / ".release-version").read_text(), "5.13.0\n")
        self.assertEqual((self.mpv / "fonts").read_text(), "conflict")

    def test_help_does_not_access_network(self):
        result = self.install("--help")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(self.requests.exists())


if __name__ == "__main__":
    unittest.main()
