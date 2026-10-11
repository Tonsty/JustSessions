import Foundation
import Testing

/// Rounded shapes take one of `ThemeCornerRadius`'s radii, through `RoundedRectangle(_:)`, so controls, rows, and
/// cards of the same kind have the same corners, all continuous as macOS draws its own.
struct UICornerRadiusContractTests {
    @Test func viewsNameNoCornerRadiusOfTheirOwn() throws {
        let literalRadius = try Regex(#"[cC]ornerRadius[A-Za-z]*(: CGFloat)? *[:=] *[0-9]"#)
        let offendingLines = try ViewSourceLines().lines(matching: literalRadius)
        #expect(offendingLines.isEmpty, "Use ThemeCornerRadius:\n\(offendingLines.joined(separator: "\n"))")
    }
}
