import Foundation
import Testing

/// The system segmented picker marks its selected segment with a gray that barely differs from its track on dark theme
/// surfaces. Views use `ThemeSegmentedPicker`, which keeps the system one only as what VoiceOver reads.
struct ThemeSegmentedPickerContractTests {
    @Test func viewsUseTheThemesSegmentedPicker() throws {
        let viewsDirectory = RepositoryFiles.rootDirectory.appendingPathComponent("Sources/JustSessions/Views")
        let files = try #require(FileManager.default.enumerator(at: viewsDirectory, includingPropertiesForKeys: nil))
        var offendingLines: [String] = []
        for case let file as URL in files
        where file.pathExtension == "swift" && file.lastPathComponent != "ThemeSegmentedPicker.swift" {
            let lines = try String(contentsOf: file, encoding: .utf8).split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() where line.contains(".pickerStyle(.segmented)") {
                offendingLines.append("\(file.lastPathComponent):\(index + 1): \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
        #expect(offendingLines.isEmpty, "\(offendingLines.joined(separator: "\n"))")
    }
}
