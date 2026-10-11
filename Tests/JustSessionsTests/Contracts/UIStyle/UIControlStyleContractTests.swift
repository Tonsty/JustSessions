import Foundation
import Testing

/// Buttons, checkboxes, and fields take the theme's styles, which draw in its colors; the system's styles draw in the
/// system accent and grays. See docs/development/ui-style.md for which style each kind of button takes.
struct UIControlStyleContractTests {
    @Test func viewsUseTheThemesButtonAndFieldStyles() throws {
        let systemStyle = try Regex(
            #"\.(buttonStyle|toggleStyle|textFieldStyle)\(\.(automatic|bordered|borderedProminent|borderless|plain|link|accessoryBar|accessoryBarAction|switch|checkbox|button|roundedBorder|squareBorder)\b"#
        )
        // A custom search field draws the themed surface around a plain field itself.
        let plainFieldInSearchField = try Regex(#"\.textFieldStyle\(\.plain\)"#)
        let offendingLines = try ViewSourceLines().lines(matching: systemStyle).filter { line in
            !(line.contains("Search") && line.contains(plainFieldInSearchField))
        }
        #expect(offendingLines.isEmpty, "Use the theme's styles in Views/Theme:\n\(offendingLines.joined(separator: "\n"))")
    }

    /// The system segmented picker marks its selected segment with a gray that barely differs from its track on dark
    /// theme surfaces. Views use `ThemeSegmentedPicker`, which keeps the system one only as what VoiceOver reads.
    @Test func viewsUseTheThemesSegmentedPicker() throws {
        let systemSegmentedPicker = try Regex(#"\.pickerStyle\(\.segmented\)"#)
        let offendingLines = try ViewSourceLines().lines(matching: systemSegmentedPicker)
        #expect(offendingLines.isEmpty, "Use ThemeSegmentedPicker:\n\(offendingLines.joined(separator: "\n"))")
    }

    /// On macOS only a disclosure group's chevron opens it; `ThemeDisclosureTitleButton` makes its title open it too.
    @Test func disclosureGroupTitlesOpenTheGroup() throws {
        let disclosureGroup = try Regex(#"\bDisclosureGroup\("#)
        let offendingFiles = try ViewSourceLines().files
            .filter { file in
                file.lines.contains { $0.contains(disclosureGroup) }
                    && !file.lines.contains { $0.contains("ThemeDisclosureTitleButton") }
            }
            .map(\.path)
        #expect(offendingFiles.isEmpty, "Use ThemeDisclosureTitleButton as the title:\n\(offendingFiles.joined(separator: "\n"))")
    }

    /// A menu's `Divider()` is a menu separator, which macOS draws. Between views, `ThemeDivider` draws the theme's line.
    @Test func dividersBetweenViewsAreTheThemes() throws {
        let source = try ViewSourceLines()
        let menuBuilder = try Regex(#"Menu|menu|Commands|Picker"#)
        let systemDivider = try Regex(#"\bDivider\(\)"#)
        let offendingFiles = source.files
            .filter { file in
                file.lines.contains { $0.contains(systemDivider) } && !file.lines.contains { $0.contains(menuBuilder) }
            }
            .map(\.path)
        #expect(offendingFiles.isEmpty, "Use ThemeDivider:\n\(offendingFiles.joined(separator: "\n"))")
    }
}
