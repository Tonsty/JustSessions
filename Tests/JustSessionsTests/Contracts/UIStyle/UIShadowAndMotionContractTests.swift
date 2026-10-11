import Foundation
import Testing

/// Shadows and animations come from `ThemeShadow` and `ThemeMotion`, so what floats casts the same shadow and the
/// same kind of change moves at the same pace everywhere.
struct UIShadowAndMotionContractTests {
    @Test func viewsCastTheThemesShadows() throws {
        let systemShadow = try Regex(#"\.shadow\("#)
        let offendingLines = try ViewSourceLines().lines(matching: systemShadow)
        #expect(offendingLines.isEmpty, "Use themeShadow(_:):\n\(offendingLines.joined(separator: "\n"))")
    }

    @Test func viewsAnimateAtTheThemesPace() throws {
        let literalDuration = try Regex(#"\.(easeOut|easeIn|easeInOut|linear|spring|smooth|snappy|bouncy)\(duration: *[0-9]"#)
        let offendingLines = try ViewSourceLines().lines(matching: literalDuration)
        #expect(offendingLines.isEmpty, "Use ThemeMotion:\n\(offendingLines.joined(separator: "\n"))")
    }
}
