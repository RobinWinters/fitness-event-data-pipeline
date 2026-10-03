import Testing
@testable import FitnessEventDataPipeline

private func event(source: String = "demo", id: String = "A1", title: String = "Strength Meetup",
                   start: String = "2027-03-14T10:00:00-07:00", end: String? = nil,
                   url: String = "https://example.org/events/A1") -> RawEvent {
    RawEvent(sourceID: source, externalID: id, title: title, startsAt: start,
             endsAt: end, sourceURL: url)
}

@Test func canonicalizesTimezoneAndWhitespace() {
    let report = EventNormalizer().normalize([event(source: " DEMO ", title: " Strength\n Meetup ")])
    #expect(report.events.first?.id == "demo:A1")
    #expect(report.events.first?.title == "Strength Meetup")
    #expect(report.events.first?.startsAtUTC == "2027-03-14T17:00:00Z")
}

@Test func retransmissionDoesNotDuplicateEvents() {
    let original = event()
    let report = EventNormalizer().normalize([original, event(start: "2027-03-14T17:00:00Z"), original])
    #expect(report.events.count == 1)
    #expect(report.receipts.map(\.decision) == [.accepted, .duplicate, .duplicate])
}

@Test func conflictQuarantinesAllRelatedRows() {
    let report = EventNormalizer().normalize([event(), event(), event(title: "Changed title"), event()])
    #expect(report.events.isEmpty)
    #expect(report.receipts.count == 4)
    #expect(report.receipts.allSatisfy { $0.decision == .conflict })
}

@Test func conflictPolicyDoesNotDependOnInputOrder() {
    let a = event(), b = event(title: "Changed title"), independent = event(id: "B2")
    let first = EventNormalizer().normalize([a, b, independent])
    let second = EventNormalizer().normalize([independent, b, a])
    #expect(first.events == second.events)
    #expect(first.events.map(\.id) == ["demo:B2"])
}

@Test func sameExternalIDFromDifferentSourcesStaysSeparate() {
    let report = EventNormalizer().normalize([event(source: "feed-a"), event(source: "feed-b")])
    #expect(report.events.map(\.id) == ["feed-a:A1", "feed-b:A1"])
}

@Test func invalidRowsDoNotEraseIndependentValidRows() {
    let report = EventNormalizer().normalize([event(id: "valid"), event(title: "  "), event(id: "bad:id")])
    #expect(report.events.map(\.id) == ["demo:valid"])
    #expect(report.receipts.map(\.decision) == [.accepted, .rejected, .rejected])
    #expect(report.receipts.map(\.reason) == ["validated", "empty_title", "invalid_external_id"])
}

@Test func timezoneMustBeExplicit() {
    let report = EventNormalizer().normalize([event(start: "2027-03-14T10:00:00")])
    #expect(report.events.isEmpty)
    #expect(report.receipts.first?.reason == "invalid_start_timestamp")
}

@Test func rejectsNonexistentCalendarDateAndInvalidHour() {
    let report = EventNormalizer().normalize([event(start: "2027-02-30T10:00:00Z"), event(start: "2027-03-14T24:00:00Z")])
    #expect(report.events.isEmpty)
    #expect(report.receipts.allSatisfy { $0.reason == "invalid_start_timestamp" })
}

@Test func endMustBeLaterAndValid() {
    let report = EventNormalizer().normalize([event(end: "2027-03-14T16:59:59Z"), event(end: "tomorrow")])
    #expect(report.events.isEmpty)
    #expect(report.receipts.map(\.reason) == ["end_not_after_start", "invalid_end_timestamp"])
}

@Test func sourceURLRequiresHttpsAndNoEmbeddedCredentials() {
    let report = EventNormalizer().normalize([event(url: "http://example.org/event"), event(url: "https://user:password@example.org/event"), event(url: "https://example.org/event#fragment")])
    #expect(report.events.isEmpty)
    #expect(report.receipts.allSatisfy { $0.reason == "invalid_https_source_url" })
}

@Test func preservesUnknownEndAndDoesNotMergeByTitle() {
    let report = EventNormalizer().normalize([event(id: "one"), event(id: "two")])
    #expect(report.events.count == 2)
    #expect(report.events.allSatisfy { $0.endsAtUTC == nil })
}

@Test func sortedOutputIsStableAcrossIndependentInputOrdering() {
    let first = EventNormalizer().normalize([event(id: "Z"), event(id: "A")])
    let second = EventNormalizer().normalize([event(id: "A"), event(id: "Z")])
    #expect(first.events == second.events)
    #expect(first.events.map(\.id) == ["demo:A", "demo:Z"])
}
