"""Send pqiv its native fit action after the WM assigns the initial tile."""

import subprocess
import sys
import time


def main():
    deadline = time.monotonic() + 5
    previous = None
    stable = 0
    while time.monotonic() < deadline:
        try:
            found = subprocess.run(
                ["xdotool", "search", "--onlyvisible", "--all", "--pid", sys.argv[1],
                 "--class", "^Pqiv$"],
                check=False, capture_output=True, text=True, timeout=0.5,
            )
            windows = found.stdout.splitlines()
            if not windows:
                time.sleep(0.05)
                continue
            geometry = subprocess.run(
                ["xdotool", "getwindowgeometry", "--shell", windows[0]],
                check=False, capture_output=True, text=True, timeout=0.5,
            )
            if geometry.returncode:
                break
            if geometry.stdout == previous:
                stable += 1
            else:
                previous, stable = geometry.stdout, 0
            if stable >= 3:
                print("toggle_scale_mode(5)", flush=True)
                return
        except (FileNotFoundError, subprocess.TimeoutExpired):
            break
        except BrokenPipeError:
            return
        time.sleep(0.05)


if __name__ == "__main__":
    main()
