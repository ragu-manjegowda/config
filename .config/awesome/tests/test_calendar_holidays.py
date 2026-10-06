#!/usr/bin/python3
"""Holiday/cache tests use no network, OAuth credentials, mail or display hardware."""

import argparse
import os
import runpy
import subprocess
import tempfile
import time
import unittest
import urllib.request
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
NS = runpy.run_path(str(ROOT / "utilities/network/calendar-holidays"))
GLOBALS = NS["sync"].__globals__


class HolidayTests(unittest.TestCase):
    def setUp(self):
        for owner, method in [(subprocess, "run"), (urllib.request, "urlopen")]:
            guard = patch.object(
                owner, method, side_effect=AssertionError("Unexpected live IO")
            )
            guard.start()
            self.addCleanup(guard.stop)
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        base = Path(self.temp.name)
        self.args = argparse.Namespace(
            year=2026,
            cache=base / "cache/holidays.json",
            include_outlook=True,
            company_pattern=NS["COMPANY_PATTERN"],
            oauth_script=base / "oauth.py",
            token_file=base / "token",
            force=False,
        )

    def login(self):
        self.args.oauth_script.touch()
        self.args.token_file.touch()

    def test_three_year_window_and_observed_boundary(self):
        start, end = NS["window"](2026)
        self.assertEqual(
            (start.isoformat(), end.isoformat()), ("2025-01-01", "2028-01-01")
        )
        events = NS["federal_holidays"](start, end)
        dates = {(item["date"], item["title"]) for item in events}
        self.assertIn(("2026-07-03", "Independence Day (observed)"), dates)
        self.assertIn(("2026-07-04", "Independence Day"), dates)
        self.assertIn(("2027-12-31", "New Year's Day (observed)"), dates)
        self.assertTrue(
            all(start.isoformat() <= item["date"] < end.isoformat() for item in events)
        )

    def test_public_feed_uses_three_years_and_excludes_regional_entries(self):
        requests = []

        def request(url, _deadline):
            requests.append(url)
            return [
                {
                    "date": "2026-04-03",
                    "global": False,
                    "name": "Regional holiday",
                }
            ]

        with patch.dict(GLOBALS, {"request_json": request}):
            events = NS["us_holidays"](*NS["window"](2026), time.monotonic() + 5)
        self.assertEqual(len(requests), 3)
        self.assertTrue(any("/2025/US" in url for url in requests))
        self.assertFalse(any(event["title"] == "Regional holiday" for event in events))

    def test_work_pagination_all_day_filter_and_exclusive_end(self):
        requests = []

        def request(url, _deadline, headers):
            requests.append(url)
            self.assertEqual(headers["Authorization"], "Bearer fixture-token")
            if len(requests) == 1:
                return {
                    "value": [
                        {
                            "subject": "Company holiday",
                            "isAllDay": True,
                            "start": {"dateTime": "2026-12-24T08:00:00"},
                            "end": {"dateTime": "2026-12-26T08:00:00"},
                        },
                        {"subject": "Holiday planning", "isAllDay": False},
                        {"subject": "Planning review", "isAllDay": True},
                        {
                            "subject": "Cancelled holiday",
                            "isAllDay": True,
                            "isCancelled": True,
                        },
                    ],
                    "@odata.nextLink": "https://graph.microsoft.com/v1.0/me/calendarView?$skip=1000",
                }
            return {"value": []}

        with patch.dict(
            GLOBALS,
            {
                "access_token": lambda *_: "fixture-token",
                "request_json": request,
            },
        ):
            events = NS["work_holidays"](
                *NS["window"](2026),
                self.args.oauth_script,
                self.args.token_file,
                self.args.company_pattern,
                time.monotonic() + 5,
            )
        self.assertEqual(
            [event["date"] for event in events], ["2026-12-24", "2026-12-25"]
        )
        self.assertEqual(len(requests), 2)
        self.assertIn("isAllDay+eq+true", requests[0])

    def test_pagination_must_not_send_tokens_to_other_hosts(self):
        with (
            patch.dict(
                GLOBALS,
                {
                    "access_token": lambda *_: "fixture-token",
                    "request_json": lambda *_: {
                        "value": [],
                        "@odata.nextLink": "https://example.com/next",
                    },
                },
            ),
            self.assertRaisesRegex(RuntimeError, "pagination URL"),
        ):
            NS["work_holidays"](
                *NS["window"](2026),
                self.args.oauth_script,
                self.args.token_file,
                self.args.company_pattern,
                time.monotonic() + 5,
            )

    def test_existing_login_is_automatic_and_new_login_invalidates_us_only_cache(
        self,
    ):
        called = []

        def work(start, end, oauth, token, pattern, deadline):
            called.append((oauth, token))
            return [
                {
                    "date": "2026-12-24",
                    "title": "Company holiday",
                    "source": "work",
                }
            ]

        with patch.dict(
            GLOBALS,
            {
                "us_holidays": lambda start, end, _: NS["federal_holidays"](start, end),
                "work_holidays": work,
            },
        ):
            first = NS["sync"](self.args)
            self.assertEqual(called, [])
            self.login()
            second = NS["sync"](self.args)
        self.assertNotEqual(first["signature"], second["signature"])
        self.assertEqual(called, [(self.args.oauth_script, self.args.token_file)])
        self.assertTrue(any(event["source"] == "work" for event in second["events"]))
        self.assertEqual(os.stat(self.args.cache).st_mode & 0o777, 0o600)
        self.assertEqual(list(self.args.cache.parent.glob(".calendar-holidays-*")), [])

    def test_fresh_cache_avoids_network_and_authentication(self):
        with patch.dict(
            GLOBALS,
            {"us_holidays": lambda start, end, _: NS["federal_holidays"](start, end)},
        ):
            expected = NS["sync"](self.args)
        with patch.dict(
            GLOBALS,
            {"us_holidays": lambda *_: self.fail("Cache should avoid network")},
        ):
            self.assertEqual(NS["sync"](self.args), expected)

    def test_offline_fallback_and_failed_work_refresh_preserve_old_holidays(
        self,
    ):
        self.login()
        with patch.dict(
            GLOBALS,
            {
                "us_holidays": lambda start, end, _: NS["federal_holidays"](start, end),
                "work_holidays": lambda *_: [
                    {
                        "date": "2026-12-24",
                        "title": "Company holiday",
                        "source": "work",
                    }
                ],
            },
        ):
            NS["sync"](self.args)
        self.args.force = True

        def failed(*_):
            raise RuntimeError("Unavailable")

        with patch.dict(GLOBALS, {"us_holidays": failed, "work_holidays": failed}):
            payload = NS["sync"](self.args)
        self.assertTrue(payload["ok"])
        self.assertEqual(len(payload["errors"]), 2)
        self.assertTrue(any(event["source"] == "work" for event in payload["events"]))
        self.assertTrue(
            any(event["date"] == "2026-12-25" for event in payload["events"])
        )

    def test_auth_is_bounded_and_error_does_not_expose_command_output(self):
        def run(*_args, **kwargs):
            self.assertGreater(kwargs["timeout"], 0)
            self.assertLessEqual(kwargs["timeout"], 12)
            return subprocess.CompletedProcess([], 1, "private-output", "private-error")

        with (
            patch.object(subprocess, "run", side_effect=run),
            self.assertRaisesRegex(
                RuntimeError, "^Work-calendar authentication failed$"
            ),
        ):
            NS["access_token"](
                self.args.oauth_script,
                self.args.token_file,
                time.monotonic() + 5,
            )


if __name__ == "__main__":
    unittest.main()
