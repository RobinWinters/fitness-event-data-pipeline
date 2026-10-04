#!/usr/bin/env python3
"""Run CLI contract checks using only the public package and synthetic fixture."""
from pathlib import Path
import json
import subprocess
import sys

root = Path(__file__).resolve().parents[1]
binary = Path(sys.argv[1]).resolve() if len(sys.argv) == 2 else root / ".build/debug/normalize-events"

def require(condition, message):
    if not condition:
        raise RuntimeError(message)

def run(data):
    return subprocess.run([str(binary)], input=data, stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE, timeout=20, check=False)

fixture = run((root / "Fixtures/synthetic-events.json").read_bytes())
require(fixture.returncode == 0, "Synthetic fixture failed")
require(not fixture.stderr, "Synthetic fixture wrote an error")
expected = json.loads((root / "Fixtures/expected-output.json").read_text())
require(json.loads(fixture.stdout) == expected, "Fixture output differs from expected events and receipts")

empty = run(b"[]")
require(empty.returncode == 0 and not empty.stderr, "Empty array is not a successful input")
require(json.loads(empty.stdout) == {"events": [], "receipts": []}, "Empty-array report differs")

for label, data in [("malformed JSON", b"{"), ("wrong top-level shape", b"{}")]:
    rejected = run(data)
    require(rejected.returncode == 1, label + " must exit with status 1")
    require(not rejected.stdout, label + " must not emit a success report")
    require(rejected.stderr == b"Invalid input: expected a JSON array matching RawEvent.\n",
            label + " must report the input contract")

print(json.dumps({"cliChecks": 4, "fixtureEvents": len(expected["events"]),
                  "fixtureReceipts": len(expected["receipts"]), "status": "pass"}, sort_keys=True))
