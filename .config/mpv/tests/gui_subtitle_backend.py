#!/usr/bin/env python3
"""Deterministic replacement for uosc's external subtitle service helper."""

import json
import os
import sys
import time
from pathlib import Path

arguments = sys.argv[1:]
with Path(os.environ["GUI_REQUESTS"]).open("a") as output:
    output.write(json.dumps(arguments) + "\n")
scenario = Path(os.environ["GUI_SCENARIO"]).read_text()
if scenario == "slow":
    time.sleep(0.4)
if arguments[0] == "search-subtitles":
    if scenario == "failure":
        print("Fixture service unavailable", file=sys.stderr)
        sys.exit(1)
    results = (
        []
        if scenario == "empty"
        else [
            {
                "attributes": {
                    "release": "GUI Fixture Alternate",
                    "language": "en",
                    "files": [{"file_id": 41}],
                }
            },
            {
                "attributes": {
                    "release": "GUI Fixture English",
                    "language": "en",
                    "files": [{"file_id": 42}],
                }
            },
        ]
    )
    print(json.dumps({"data": results, "page": 1, "total_pages": 1}))
elif arguments[0] == "download-subtitles":
    destination = Path(arguments[arguments.index("--destination") + 1])
    destination.mkdir(parents=True, exist_ok=True)
    subtitle = destination / "gui-fixture.srt"
    subtitle.write_text("1\n00:00:00,000 --> 00:01:00,000\nGUI fixture subtitle\n")
    print(
        json.dumps(
            {
                "file": str(subtitle),
                "remaining": 9,
                "total": 10,
                "reset_time": "00:00",
            }
        )
    )
else:
    print("Unexpected helper command: " + repr(arguments), file=sys.stderr)
    sys.exit(2)
