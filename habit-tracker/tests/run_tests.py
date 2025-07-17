#!/usr/bin/env python3
"""
Test runner for Habit Tracker application.
"""

import subprocess
import sys


def run_tests():
    """Run all tests and return the exit code."""
    print("🧪 Running Habit Tracker Tests...")
    print("=" * 50)

    # Run pytest with verbose output
    result = subprocess.run(
        [
            sys.executable,
            "-m",
            "pytest",
            ".",
            "-v",
            "--tb=short",
            "--disable-warnings",
        ],
        capture_output=True,
        text=True,
    )

    # Print output
    print(result.stdout)
    if result.stderr:
        print("Errors:", result.stderr)

    print("=" * 50)
    if result.returncode == 0:
        print("✅ All tests passed!")
    else:
        print("❌ Some tests failed!")

    return result.returncode


if __name__ == "__main__":
    exit_code = run_tests()
    sys.exit(exit_code)
