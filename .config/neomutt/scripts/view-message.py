#!/usr/bin/env python3
"""Open a complete MIME message with headers, inline images, and attachments."""

import argparse
import base64
import html
import mimetypes
import os
import re
import subprocess
import sys
import tempfile
from email import policy
from email.parser import BytesParser
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlsplit

CSP = (
    "default-src 'none'; script-src 'none'; style-src 'unsafe-inline'; "
    "img-src data: http: https:; frame-src 'self'; object-src 'none'; "
    "base-uri 'none'; form-action 'none'"
)


def text_content(part):
    try:
        return part.get_content()
    except (LookupError, UnicodeError):
        return (part.get_payload(decode=True) or b"").decode("utf-8", errors="replace")


class RelatedImages(HTMLParser):
    """Resolve MIME references without running HTML or fetching remote resources."""

    def __init__(self, references, base=""):
        super().__init__(convert_charrefs=False)
        self.references = references
        self.base = base
        self.parts = []
        self.in_style = False

    def reference(self, value):
        value = value.strip()
        key = unquote(value[4:]).strip("<>") if value.lower().startswith("cid:") else value
        if key in self.references:
            return self.references[key]
        if self.base and not urlsplit(value).scheme and not value.startswith("#"):
            return urljoin(self.base, value)
        return value

    def css(self, value):
        return re.sub(
            r"url\(\s*(['\"]?)([^)'\"]+)\1\s*\)",
            lambda match: 'url("' + self.reference(match[2]).replace('"', "%22") + '")',
            value, flags=re.IGNORECASE,
        )

    def start(self, tag, attributes, closing=""):
        values = dict(attributes)
        if tag == "base":
            if urlsplit(values.get("href", "")).scheme in ("http", "https"):
                self.base = values["href"]
            return
        if tag == "a":
            values["target"] = "_blank"
            values["rel"] = "noopener noreferrer"
        for name, value in list(values.items()):
            if value is None:
                continue
            if name in ("src", "href", "background", "poster"):
                values[name] = self.reference(value)
            elif name == "style":
                values[name] = self.css(value)
            elif name == "srcset":
                values[name] = re.sub(r"cid:[^\s,]+", lambda match: self.reference(match[0]),
                                      value, flags=re.IGNORECASE)
        attributes = "".join(
            " " + name if value is None else f' {name}="{html.escape(value, quote=True)}"'
            for name, value in values.items()
        )
        self.parts.append(f"<{tag}{attributes}{closing}>")
        if tag == "style":
            self.in_style = True

    def handle_starttag(self, tag, attrs):
        self.start(tag, attrs)

    def handle_startendtag(self, tag, attrs):
        self.start(tag, attrs, " /")

    def handle_endtag(self, tag):
        self.parts.append(f"</{tag}>")
        if tag == "style":
            self.in_style = False

    def handle_data(self, data):
        self.parts.append(self.css(data) if self.in_style else data)

    def handle_entityref(self, name):
        self.parts.append(f"&{name};")

    def handle_charref(self, name):
        self.parts.append(f"&#{name};")

    def handle_comment(self, data):
        self.parts.append("<!--" + data + "-->")

    def handle_decl(self, decl):
        self.parts.append("<!" + decl + ">")


def render_message(raw, parent=None):
    message = BytesParser(policy=policy.default).parsebytes(raw)
    directory = Path(tempfile.mkdtemp(prefix=f"neomutt-message-{os.getuid()}-", dir=parent))
    directory.chmod(0o700)
    references = {}
    attachments = []
    for index, part in enumerate(message.walk()):
        if part.is_multipart():
            continue
        payload = part.get_payload(decode=True) or b""
        content_type = part.get_content_type()
        content_id = str(part.get("Content-ID", "")).strip().strip("<>")
        location = str(part.get("Content-Location", "")).strip()
        image = ""
        if content_type.startswith("image/"):
            image = "data:" + content_type + ";base64," + base64.b64encode(payload).decode("ascii")
            if content_id:
                references[content_id] = image
            if location:
                references[location] = image
        filename = part.get_filename()
        if part.is_attachment() or (filename and not content_id and not location):
            # Never use an untrusted MIME filename as a filesystem path.
            extension = mimetypes.guess_extension(content_type) or ".bin"
            asset = directory / f"attachment-{index:03d}{extension}"
            with asset.open("xb") as output:
                output.write(payload)
            asset.chmod(0o600)
            label = html.escape(filename or f"Attachment {index}")
            thumbnail = f'<img alt="" src="{image}">' if image else ""
            attachments.append(
                f'<a href="{asset.name}" download="{html.escape(filename or asset.name, quote=True)}">'
                f"{thumbnail}{label}</a>"
            )
    body = message.get_body(preferencelist=("html", "plain"))
    if body is None:
        content = "<p>No displayable text body is available.</p>"
    elif body.get_content_type() == "text/html":
        base = str(body.get("Content-Base", message.get("Content-Base", "")))
        rewriter = RelatedImages(references, base)
        rewriter.feed(text_content(body))
        rewriter.close()
        content = "".join(rewriter.parts)
    else:
        content = '<pre style="white-space:pre-wrap">' + html.escape(text_content(body)) + "</pre>"
    headers = []
    for name in ("From", "Sender", "To", "Cc", "Bcc", "Reply-To", "Date"):
        value = str(message.get(name, ""))
        if value:
            headers.append(f"<dt>{name}</dt><dd>{html.escape(value)}</dd>")
    subject = html.escape(str(message.get("Subject", "(No subject)")))
    attachment_section = '<div class="attachments">' + "".join(attachments) + "</div>" if attachments else ""
    document = f"""<!doctype html>
<html><head><meta charset="utf-8">
<meta http-equiv="Content-Security-Policy" content="{html.escape(CSP, quote=True)}">
<title>{subject}</title>
<style>
body {{ margin:0; height:100vh; display:flex; flex-direction:column; font:15px sans-serif; }}
header {{ padding:16px 24px; background:#f4f5f7; color:#202124; max-height:40vh; overflow:auto; }}
h1 {{ font-size:19px; margin:0 0 12px; overflow-wrap:anywhere; }}
dl {{ display:grid; grid-template-columns:max-content minmax(0,1fr); gap:6px 16px; margin:0; }}
dt {{ font-weight:bold; }} dd {{ margin:0; white-space:pre-wrap; overflow-wrap:anywhere; }}
iframe {{ flex:1; min-height:0; width:100%; border:0; }}
.attachments {{ display:flex; gap:12px; flex-wrap:wrap; margin-top:12px; }}
.attachments a {{ display:flex; flex-direction:column; gap:4px; overflow-wrap:anywhere; }}
.attachments img {{ max-width:180px; max-height:120px; object-fit:contain; }}
</style></head><body>
<header><h1>{subject}</h1><dl>{''.join(headers)}</dl>{attachment_section}</header>
<iframe title="Message body" sandbox="allow-same-origin allow-popups allow-popups-to-escape-sandbox"
srcdoc="{html.escape(content, quote=True)}"></iframe>
</body></html>
"""
    destination = directory / "message.html"
    destination.write_text(document, encoding="utf-8")
    destination.chmod(0o600)
    return destination


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--no-open", action="store_true", help="Render privately and print the HTML path")
    args = parser.parse_args()
    os.umask(0o077)
    destination = render_message(sys.stdin.buffer.read())
    if args.no_open:
        print(destination)
    else:
        subprocess.Popen(
            ["firefox", "--new-window", destination.as_uri()],
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,
        )


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        print(f"view-message: {error}", file=sys.stderr)
        sys.exit(1)
