import Foundation

/// Synthetic teaching input. Source IDs identify feeds, not independent verification.
public struct RawEvent: Codable, Sendable {
    public let sourceID: String
    public let externalID: String
    public let title: String
    public let startsAt: String
    public let endsAt: String?
    public let sourceURL: String

    public init(sourceID: String, externalID: String, title: String,
                startsAt: String, endsAt: String? = nil, sourceURL: String) {
        self.sourceID = sourceID; self.externalID = externalID; self.title = title
        self.startsAt = startsAt; self.endsAt = endsAt; self.sourceURL = sourceURL
    }
}

public struct NormalizedEvent: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let sourceID: String
    public let externalID: String
    public let title: String
    public let startsAtUTC: String
    public let endsAtUTC: String?
    public let sourceURL: String
}

public enum Decision: String, Codable, Sendable {
    case accepted, duplicate, rejected, conflict
}

public struct Receipt: Codable, Equatable, Sendable {
    public let inputIndex: Int
    public let id: String?
    public let decision: Decision
    public let reason: String
}

public struct NormalizationReport: Codable, Equatable, Sendable {
    public let events: [NormalizedEvent]
    public let receipts: [Receipt]
}

public struct EventNormalizer: Sendable {
    public init() {}

    /// Invalid rows are rejected individually. Conflicting valid rows sharing an
    /// identity are all quarantined; input order never chooses a winning payload.
    public func normalize(_ input: [RawEvent]) -> NormalizationReport {
        var events: [String: NormalizedEvent] = [:]
        var rows: [String: [Int]] = [:]
        var conflicts: Set<String> = []
        var receipts: [Receipt] = []

        for (index, raw) in input.enumerated() {
            let candidate: NormalizedEvent
            do { candidate = try validate(raw) }
            catch let error as ValidationError {
                receipts.append(Receipt(inputIndex: index, id: nil,
                                        decision: .rejected, reason: error.rawValue))
                continue
            } catch {
                receipts.append(Receipt(inputIndex: index, id: nil,
                                        decision: .rejected, reason: "validation_failed"))
                continue
            }

            let id = candidate.id
            rows[id, default: []].append(index)
            if conflicts.contains(id) || (events[id] != nil && events[id] != candidate) {
                conflicts.insert(id)
                events.removeValue(forKey: id)
                receipts.append(Receipt(inputIndex: index, id: id,
                                        decision: .conflict, reason: "conflicting_payload"))
                for affected in rows[id, default: []] {
                    receipts[affected] = Receipt(inputIndex: affected, id: id,
                                                 decision: .conflict, reason: "conflicting_payload")
                }
            } else if events[id] != nil {
                receipts.append(Receipt(inputIndex: index, id: id,
                                        decision: .duplicate, reason: "same_normalized_payload"))
            } else {
                events[id] = candidate
                receipts.append(Receipt(inputIndex: index, id: id,
                                        decision: .accepted, reason: "validated"))
            }
        }
        return NormalizationReport(events: events.values.sorted { $0.id < $1.id },
                                   receipts: receipts)
    }

    private enum ValidationError: String, Error {
        case source = "invalid_source_id"
        case external = "invalid_external_id"
        case title = "empty_title"
        case start = "invalid_start_timestamp"
        case end = "invalid_end_timestamp"
        case chronology = "end_not_after_start"
        case url = "invalid_https_source_url"
    }

    private func validate(_ raw: RawEvent) throws -> NormalizedEvent {
        let source = raw.sourceID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let external = raw.externalID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard matches(source, #"^[a-z0-9][a-z0-9-]{0,63}$"#) else { throw ValidationError.source }
        guard matches(external, #"^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$"#) else { throw ValidationError.external }
        let title = raw.title.split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !title.isEmpty else { throw ValidationError.title }
        guard let start = parseTimestamp(raw.startsAt) else { throw ValidationError.start }
        var end: Date?
        if let text = raw.endsAt {
            guard let value = parseTimestamp(text) else { throw ValidationError.end }
            guard value > start else { throw ValidationError.chronology }
            end = value
        }
        guard let url = URL(string: raw.sourceURL), url.scheme == "https",
              let host = url.host, !host.isEmpty, url.user == nil, url.password == nil,
              url.fragment == nil else { throw ValidationError.url }
        return NormalizedEvent(id: source + ":" + external, sourceID: source,
                               externalID: external, title: title,
                               startsAtUTC: canonical(start),
                               endsAtUTC: end.map(canonical), sourceURL: url.absoluteString)
    }

    private func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }

    private func parseTimestamp(_ text: String) -> Date? {
        // Require seconds and an explicit offset; do not guess local timezone,
        // all-day semantics or nonexistent calendar dates.
        let pattern = #"^[12][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T([01][0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](Z|[+-]([01][0-9]|2[0-3]):[0-5][0-9])$"#
        guard matches(text, pattern) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
        formatter.isLenient = false
        return formatter.date(from: text)
    }

    private func canonical(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
