import Foundation
import Testing

/// The system's `.secondary` and `.tertiary` text is 3.0 and 1.7 on the light themes' surfaces, its red falls short
/// too, and `.primary` and the named system colors ignore the chosen theme. Views draw in `ThemePalette`'s colors,
/// which follow the theme and are readable on every surface.
struct UIColorContractTests {
    @Test func viewsDrawInTheThemesColors() throws {
        let systemColor = try Regex(
            #"(foregroundStyle|foregroundColor|fill|stroke|strokeBorder|background|tint)\([^)]*\.(primary|secondary|tertiary|quaternary|red|orange|yellow|green|mint|teal|cyan|blue|indigo|purple|pink|brown|gray|white|black|accentColor)\b"#
        )
        let offendingLines = try ViewSourceLines().lines(matching: systemColor)
        #expect(offendingLines.isEmpty, "Use ThemePalette's colors:\n\(offendingLines.joined(separator: "\n"))")
    }
}
