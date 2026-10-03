# ``FitnessEventDataPipeline``

Turn synthetic event rows into normalized events and inspectable decisions.

## Overview

This dependency-free Swift teaching package demonstrates validation, source identity, duplicate handling and conflict quarantine. Robin Winters prepared it with coding-assistant support as a public educational companion to work in native iOS and fitness technology.

It is separate from private ShowFlex code. It does not demonstrate a released application feature, a customer integration, live event ingestion or independently verified performance. The supplied fixture contains synthetic records and placeholder source URLs.

Start with <doc:InspectingNormalization> to run the existing command-line example and inspect why each input row was accepted, duplicated, rejected or quarantined.

``EventNormalizer`` performs the transformation without network requests. Its ``EventNormalizer/normalize(_:)`` method returns a ``NormalizationReport`` containing sorted ``NormalizedEvent`` values and one ``Receipt`` per input row. ``Decision`` identifies the disposition of each row.

For approved professional work and shipped-product evidence, see [Robin Winters's professional record](https://github.com/RobinWinters/RobinWinters/tree/Radpository/professional) and the [ShowFlex iPhone listing](https://apps.apple.com/us/app/showflex/id6757890910).

## Topics

### Walkthrough

- <doc:InspectingNormalization>

### Input and transformation

- ``RawEvent``
- ``EventNormalizer``
- ``EventNormalizer/normalize(_:)``

### Output and row decisions

- ``NormalizationReport``
- ``NormalizedEvent``
- ``Receipt``
- ``Decision``
