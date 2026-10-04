# Changelog

## 0.1.1 — October 3, 2026

Verification and documentation release. Library behavior, public types, CLI input/output and the synthetic fixture are unchanged from 0.1.0.

- Add public GitHub Actions builds/tests on macOS 15 and Ubuntu 24.04, plus a digest-pinned official Swift 6.0.3 Linux container.
- Add four reusable CLI contract checks: complete fixture equivalence, empty-array success, malformed-JSON rejection and wrong-top-level-shape rejection.
- Record the successful [three-job CI run](https://github.com/RobinWinters/fitness-event-data-pipeline/actions/runs/37172573330), exact observed toolchains and limits in [compatibility.json](compatibility.json).
- Align author/version citation metadata with this release and retain the standalone educational-code and coding-assistant attribution.

Each CI job passed twelve Swift tests. The macOS/Ubuntu host jobs passed four CLI checks; the Swift 6.0.3 job compared the full fixture output. No iOS-device, production integration, customer deployment or performance result is inferred.

## 0.1.0

Initial standalone Swift teaching package with explicit timestamp validation, stable event identity, duplicate handling, conflict quarantine and one receipt per input row. Existing tag and attribution retained.
