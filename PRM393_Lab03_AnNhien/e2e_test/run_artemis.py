"""Chạy pytest ARTEMIS lặp lại và lưu evidence không chứa biến môi trường."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from datetime import UTC, datetime
from pathlib import Path
from xml.etree import ElementTree


def outcome(xml_file: Path) -> dict[str, int]:
    root = ElementTree.parse(xml_file).getroot()
    suites = [root] if root.tag == "testsuite" else root.findall("testsuite")
    return {
        "tests": sum(int(suite.attrib.get("tests", 0)) for suite in suites),
        "failures": sum(int(suite.attrib.get("failures", 0)) for suite in suites),
        "errors": sum(int(suite.attrib.get("errors", 0)) for suite in suites),
        "skipped": sum(int(suite.attrib.get("skipped", 0)) for suite in suites),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("tests", nargs="*", default=["test_f4_task_flows.py"])
    parser.add_argument("--runs", type=int, default=3)
    args = parser.parse_args()
    if args.runs < 3:
        parser.error("Yêu cầu bài: mỗi ARTEMIS test chạy ít nhất 3 lần.")

    stamp = datetime.now(UTC).strftime("%Y%m%dT%H%M%SZ")
    evidence = Path(__file__).resolve().parents[1] / "evidence" / "artemis" / stamp
    evidence.mkdir(parents=True, exist_ok=False)
    records = []
    for index in range(1, args.runs + 1):
        xml_file = evidence / f"run-{index}.xml"
        command = [sys.executable, "-m", "pytest", "-q", *args.tests, f"--junitxml={xml_file}"]
        completed = subprocess.run(command, cwd=Path(__file__).parent, check=False)
        record = {"run": index, "exit_code": completed.returncode, **outcome(xml_file)}
        records.append(record)

    passed = sum(record["exit_code"] == 0 and record["skipped"] == 0 for record in records)
    summary = {
        "created_at_utc": stamp,
        "tests": args.tests,
        "runs": records,
        "pass_rate": f"{passed}/{args.runs}",
        "note": "Không ghi ARTEMIS_BASE_URL, token hoặc API key vào evidence.",
    }
    (evidence / "summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
    print(json.dumps(summary, indent=2))
    return 0 if passed == args.runs else 1


if __name__ == "__main__":
    raise SystemExit(main())
