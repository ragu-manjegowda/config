"""Synthetic MIME and real NeoMutt macro checks; no personal mail or browser I/O."""

import base64
import email.policy
import fcntl
import importlib.util
import json
import os
import pty
import select
import shutil
import signal
import struct
import subprocess
import sys
import tempfile
import termios
import time
import unittest
import zlib
from email.message import EmailMessage
from html.parser import HTMLParser
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SPEC = importlib.util.spec_from_file_location("view_message", ROOT / "scripts/view-message.py")
VIEW = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(VIEW)
ALIAS_SPEC = importlib.util.spec_from_file_location("create_alias", ROOT / "scripts/create-alias.py")
ALIASES = importlib.util.module_from_spec(ALIAS_SPEC)
ALIAS_SPEC.loader.exec_module(ALIASES)


def png():
    def chunk(kind, data):
        return struct.pack("!I", len(data)) + kind + data + struct.pack("!I", zlib.crc32(kind + data))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack("!2I5B", 1, 1, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(b"\0\x20\xc0\x40")) + chunk(b"IEND", b""))


def message():
    mail = EmailMessage(policy=email.policy.default)
    mail["From"] = '"Correct Actor (Jira)" <jira@notifications.example>'
    mail["To"] = '"Reader, Example" <reader@example.org>'
    mail["Cc"] = "Other Reader <other@example.org>"
    mail["Subject"] = "Synthetic rich message"
    mail["Date"] = "Mon, 26 Oct 2026 10:00:00 +0000"
    mail.set_content("Plain alternative")
    mail.add_alternative(
        '<html><body><h2>Rich body</h2><img src="cid:picture%40example" '
        'srcset="cid:picture%40example 1x">'
        '<div style="background-image:url(\'cid:picture@example\')">Background</div>'
        '<script>window.email_script_ran = true;</script></body></html>', subtype="html",
    )
    mail.get_payload()[1].add_related(png(), maintype="image", subtype="png", cid="<picture@example>")
    return mail


class Document(HTMLParser):
    def __init__(self, text):
        super().__init__()
        self.body = None
        self.sandbox = None
        self.feed(text)

    def handle_starttag(self, tag, attrs):
        if tag == "iframe":
            values = dict(attrs)
            self.body = values.get("srcdoc")
            self.sandbox = values.get("sandbox")


class ViewMessageTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="message view ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def render(self, mail):
        path = VIEW.render_message(mail.as_bytes(), self.root)
        return path, path.read_text()

    def test_real_headers_and_html_body_are_preserved(self):
        _, text = self.render(message())
        for value in ("Correct Actor (Jira)", "jira@notifications.example", "reader@example.org",
                      "other@example.org", "Synthetic rich message"):
            self.assertIn(value, text)
        self.assertIn("Rich body", Document(text).body)
        self.assertNotIn("Plain alternative", Document(text).body)

    def test_cid_images_srcset_and_css_resolve_to_embedded_data(self):
        _, text = self.render(message())
        body = Document(text).body
        self.assertNotIn("cid:", body)
        encoded = "data:image/png;base64," + base64.b64encode(png()).decode()
        self.assertIn(encoded, body)
        self.assertIn('srcset="' + encoded + ' 1x"', body)

    def test_message_html_cannot_enable_scripts_or_forms(self):
        _, text = self.render(message())
        self.assertIn("script-src &#x27;none&#x27;", text)
        self.assertNotIn("allow-scripts", Document(text).sandbox)
        self.assertNotIn("allow-forms", Document(text).sandbox)

    def test_headers_are_html_escaped(self):
        mail = message()
        mail.replace_header("Subject", '<script>alert("header")</script>')
        _, text = self.render(mail)
        self.assertIn("&lt;script&gt;", text)
        self.assertNotIn('<script>alert("header")</script>', text)

    def test_plain_text_gets_headers_and_readable_fallback(self):
        mail = EmailMessage()
        mail["From"] = "Person <person@example.org>"
        mail["To"] = "Reader <reader@example.org>"
        mail.set_content("A <plain> message & details")
        _, text = self.render(mail)
        self.assertIn("person@example.org", text)
        self.assertIn("A &lt;plain&gt; message &amp; details", Document(text).body)

    def test_attachment_paths_cannot_escape_the_private_directory(self):
        mail = message()
        mail.add_attachment(b"synthetic attachment", maintype="application", subtype="pdf",
                            filename="../../outside.pdf")
        path, text = self.render(mail)
        assets = list(path.parent.glob("attachment-*"))
        self.assertEqual(len(assets), 1)
        self.assertEqual(assets[0].read_bytes(), b"synthetic attachment")
        self.assertEqual(assets[0].stat().st_mode & 0o777, 0o600)
        self.assertEqual(path.stat().st_mode & 0o777, 0o600)
        self.assertEqual(path.parent.stat().st_mode & 0o777, 0o700)
        self.assertIn("download=", text)
        self.assertFalse((self.root / "outside.pdf").exists())

    def test_distinct_views_do_not_overwrite_previous_messages(self):
        first, _ = self.render(message())
        second, _ = self.render(message())
        self.assertNotEqual(first.parent, second.parent)
        self.assertTrue(first.exists())
        self.assertTrue(second.exists())

    def test_content_locations_and_remote_image_urls(self):
        rewriter = VIEW.RelatedImages({"picture.png": "data:image/png;base64,fixture"})
        rewriter.feed('<img src="picture.png"><img src="https://images.example.org/avatar.png">')
        text = "".join(rewriter.parts)
        self.assertIn('src="data:image/png;base64,fixture"', text)
        self.assertIn('src="https://images.example.org/avatar.png"', text)

    def test_browser_launch_uses_a_literal_file_uri(self):
        mail = message().as_bytes()
        with (
            patch.object(sys, "argv", ["view-message"]),
            patch.object(sys, "stdin") as stdin,
            patch.object(VIEW.subprocess, "Popen") as launch,
            patch.object(VIEW.tempfile, "mkdtemp", return_value=str(self.root)),
        ):
            stdin.buffer.read.return_value = mail
            old_mask = os.umask(0o077)
            try:
                VIEW.main()
            finally:
                os.umask(old_mask)
        self.assertEqual(launch.call_args.args[0],
                         ["firefox", "--new-window", (self.root / "message.html").as_uri()])
        self.assertEqual(launch.call_args.kwargs["stdin"], subprocess.DEVNULL)


class SharedSenderAliasTests(unittest.TestCase):
    def test_waiting_display_filter_uses_the_latest_blacklist(self):
        with tempfile.TemporaryDirectory() as temporary:
            path = Path(temporary) / "aliases"
            path.write_bytes(b"")
            blacklist = path.parent / "alias-blacklist"
            blacklist.write_bytes(b"")
            original_lock = ALIASES.locked_directory

            def lock_and_update(target):
                descriptor = original_lock(target)
                blacklist.write_text("jira@notifications.example\n")
                return descriptor

            with patch.object(ALIASES, "locked_directory", side_effect=lock_and_update):
                ALIASES.add_alias("From: Actor (Jira) <jira@notifications.example>\n\nBody", path)
            self.assertEqual(path.read_bytes(), b"")


@unittest.skipUnless(shutil.which("neomutt"), "Macro tests require NeoMutt")
class BrowserMacroTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="neomutt browser test ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        scripts = self.root / ".config/neomutt/scripts"
        scripts.mkdir(parents=True)
        (scripts / "view-message.py").symlink_to(ROOT / "scripts/view-message.py")
        binary = self.root / "bin"
        binary.mkdir()
        firefox = binary / "firefox"
        firefox.write_text(
            "#!/usr/bin/python3\nimport json, os, pathlib, sys\n"
            "pathlib.Path(os.environ['VIEW_TEST_BROWSER']).write_text(json.dumps(sys.argv[1:]))\n"
        )
        firefox.chmod(0o700)
        self.maildir = self.root / "maildir"
        for name in ("cur", "new", "tmp"):
            (self.maildir / name).mkdir(parents=True)
        (self.maildir / "new/fixture").write_bytes(message().as_bytes())
        self.config = self.root / "neomuttrc"
        self.environment = os.environ | {
            "HOME": str(self.root), "XDG_CONFIG_HOME": str(self.root / ".config"),
            "TMPDIR": str(self.root), "TERM": "xterm-256color",
            "PATH": f"{binary}:{os.environ['PATH']}",
            "VIEW_TEST_BROWSER": str(self.root / "browser.json"),
        }

    def exercise(self, mode, decoded):
        self.config.write_text(
            f'set quit=yes\nset wait_key=no\nset sleep_time=0\nset mail_check=0\n'
            f'set folder="{self.maildir}"\nset move=no\nset mark_old=no\n'
            f'set shell="/bin/sh"\nset pipe_decode={decoded}\n'
            'set reverse_alias=yes\nalias jira Wrong Person <jira@notifications.example>\n'
            f'source "{ROOT / "config/bindings.mutt"}"\n'
        )
        restored = self.root / "restored"
        prefix = {"index": "", "pager": "<display-message>", "attach": "<view-attachments>"}[mode]
        keys = (prefix + ",of<enter-command>setenv VIEW_TEST_DECODE $pipe_decode<enter>"
                f'<shell-escape>printenv VIEW_TEST_DECODE > "{restored}"<enter>qq')
        args = ["neomutt", "-n", "-F", str(self.config), "-f", str(self.maildir),
                "-e", "push '" + keys + "'"]
        pid, master = pty.fork()
        if pid == 0:
            try:
                fcntl.ioctl(0, termios.TIOCSWINSZ, struct.pack("HHHH", 40, 120, 0, 0))
                os.execvpe("neomutt", args, self.environment)
            finally:
                os._exit(127)
        status = None
        transcript = b""
        try:
            deadline = time.monotonic() + 15
            while status is None:
                completed, value = os.waitpid(pid, os.WNOHANG)
                if completed:
                    status = value
                    break
                if time.monotonic() > deadline:
                    self.fail("Synthetic NeoMutt macro timed out: " + transcript[-6000:].decode(errors="replace"))
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        transcript += os.read(master, 65536)
                    except OSError:
                        continue
            self.assertEqual(os.waitstatus_to_exitcode(status), 0, transcript.decode(errors="replace"))
        finally:
            os.close(master)
            if status is None:
                try:
                    os.killpg(pid, signal.SIGKILL)
                except ProcessLookupError:
                    pass
                os.waitpid(pid, 0)
        self.assertEqual(restored.read_text().strip(), decoded)
        browser = self.root / "browser.json"
        deadline = time.monotonic() + 2
        while not browser.exists() and time.monotonic() < deadline:
            time.sleep(0.01)
        arguments = json.loads(browser.read_text())
        self.assertEqual(arguments[0], "--new-window")
        from urllib.parse import unquote, urlsplit
        document = Path(unquote(urlsplit(arguments[1]).path))
        text = document.read_text()
        self.assertIn("Correct Actor (Jira)", text)
        self.assertNotIn("Wrong Person", text)
        self.assertIn("reader@example.org", text)
        self.assertIn("data:image/png;base64,", Document(text).body)

    def test_index_macro_preserves_enabled_pipe_decode(self):
        self.exercise("index", "yes")

    def test_pager_macro_preserves_disabled_pipe_decode(self):
        self.exercise("pager", "no")

    def test_attachment_macro_opens_the_complete_message(self):
        self.exercise("attach", "yes")


if __name__ == "__main__":
    unittest.main()
