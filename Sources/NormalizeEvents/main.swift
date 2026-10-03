import Foundation
import FitnessEventDataPipeline

@main
struct NormalizeEvents {
    static func main() {
        if CommandLine.arguments.contains("--help") {
            print("Read a JSON array of synthetic/raw events from stdin; write normalized events and receipts as JSON.")
            return
        }
        do {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            let rows = try JSONDecoder().decode([RawEvent].self, from: data)
            let report = EventNormalizer().normalize(rows)
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            var result = try encoder.encode(report)
            result.append(0x0a)
            FileHandle.standardOutput.write(result)
        } catch {
            FileHandle.standardError.write(Data("Invalid input: expected a JSON array matching RawEvent.\n".utf8))
            exit(1)
        }
    }
}
