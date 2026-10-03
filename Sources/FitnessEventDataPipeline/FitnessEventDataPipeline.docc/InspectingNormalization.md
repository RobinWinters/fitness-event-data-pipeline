# Inspecting normalization decisions

Run a synthetic feed through the example and review every row's disposition.

## Run the supplied fixture

From the repository root, use Swift 6.0 or later:

```sh
swift run normalize-events < Fixtures/synthetic-events.json
```

The checked fixture produces one normalized event and five receipts. Compare the JSON semantically with `Fixtures/expected-output.json`; whitespace and object-key order are not part of the contract. The executable also returns a nonzero exit status for malformed input JSON.

These are local teaching-package checks. The manifest declares macOS 13 and iOS 16 minimums, but current execution evidence is on macOS. It does not establish an iPhone-device run or a released ShowFlex data pipeline.

## Inspect events and receipts separately

The `events` array contains accepted ``NormalizedEvent`` values sorted by stable identity. The `receipts` array contains one ``Receipt`` per original input row, preserving the input index so a caller can explain omissions as well as successful output.

| Decision | Meaning |
|---|---|
| `accepted` | A valid, unique normalized payload remains in the accepted output. |
| `duplicate` | An equivalent normalized payload repeats the same source/external identity. |
| `rejected` | The row fails validation; it does not enter the accepted output. |
| `conflict` | Valid rows disagree for the same identity; every related valid row is quarantined. |

Conflict handling can revise an earlier receipt from `accepted` or `duplicate` to `conflict`. Inspect the final report rather than treating an intermediate decision as permanent. Input order never chooses a winner for conflicting valid payloads.

## Review the policy boundaries

``RawEvent`` supplies explicit timestamps and an HTTPS source URL. Source slugs are trimmed and lowercased; external identifiers remain case-sensitive. The accepted event ID joins them with a colon. Title normalization collapses whitespace; it does not merge unrelated events by title.

Dates require seconds and an explicit UTC offset. Output uses UTC. A missing end timestamp remains unknown. Unsupported date-only, fractional-second or recurrence forms need a separate policy and are outside this example.

A retained source URL is a provenance pointer. It is not independent corroboration of the event's truth. URLs containing embedded credentials or fragments are rejected; the package makes no request to them.

## Apply the library contract

Consumers call ``EventNormalizer/normalize(_:)`` with an array of ``RawEvent`` values and receive a ``NormalizationReport``. There is no persistence layer, authenticated provider integration or retry scheduler. Those decisions belong to a real ingestion service and require their own evidence and tests.
