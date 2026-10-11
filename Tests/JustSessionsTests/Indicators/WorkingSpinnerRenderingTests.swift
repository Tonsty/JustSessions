import AppKit
import Foundation
import SwiftUI
import Testing
@testable import JustSessions

/// The working spinner draws its arc in the live status color of each appearance, from a Core Animation layer: the
/// hosting view renders it once, and the turning costs SwiftUI nothing. Set `JUSTSESSIONS_THEME_SCREENSHOTS` to a
/// directory to keep the renderings.
@MainActor
struct WorkingSpinnerRenderingTests {
    /// The indicator's 10 points and 7 points of padding above and below; the width fits the content.
    private static let size = CGSize(width: 40, height: 24)
    private static let swatchSide: CGFloat = 8

    @Test(arguments: [ColorScheme.light, .dark])
    func theArcDrawsInTheLiveColorOfTheAppearance(colorScheme: ColorScheme) async throws {
        // A swatch of the live color beside the spinner, captured the same way, gives the color to look for.
        let fixture = ThemeSurfaceRenderingFixture(
            content: AnyView(
                HStack(spacing: 8) {
                    SessionStatusIndicator(status: .running(.working))
                    Rectangle().fill(ThemePalette.live).frame(width: Self.swatchSide, height: Self.swatchSide)
                }
                .padding(7)
                .background(ThemePalette.sidebarSurface)
            ),
            size: Self.size,
            colorScheme: colorScheme
        )
        defer { fixture.close() }
        let schemeName = colorScheme == .dark ? "dark" : "light"

        let bitmap = try await fixture.capture(named: "working-spinner-\(schemeName)")

        let scale = Double(bitmap.pixelsHigh) / Self.size.height
        // The swatch's center: past the padding, the indicator, and the spacing, then half the swatch.
        let swatchCenter = try #require(bitmap.colorAt(x: Int(29 * scale), y: Int(12 * scale))).sRGBHexValue
        let liveHexValue = try #require(swatchCenter)
        let livePixels = (0..<bitmap.pixelsHigh).reduce(0) { count, row in
            count + (0..<bitmap.pixelsWide).filter { column in
                bitmap.colorAt(x: column, y: row).flatMap(\.sRGBHexValue).map { matches($0, liveHexValue) } ?? false
            }.count
        }
        let swatchPixels = Int(Self.swatchSide * Self.swatchSide * scale * scale)
        let arcPixels = livePixels - swatchPixels
        // An 8-point ring 1.6 points thick is about 40 square points; the arc is 72 % of it, its edges antialiased.
        #expect(arcPixels > Int(12 * scale * scale), "\(schemeName): the arc is drawn in the live color (\(arcPixels) pixels)")
        #expect(arcPixels < Int(40 * scale * scale), "\(schemeName): only the arc is drawn (\(arcPixels) pixels)")
    }

    /// No view animates with a per-frame `TimelineView`: every tick would re-render the window's whole hosting view.
    @Test func noViewTicksATimelineEveryFrame() throws {
        let perFrameTimeline = try Regex(#"TimelineView\(\s*\.animation"#)
        let offendingLines = try ViewSourceLines().lines(matching: perFrameTimeline)
        #expect(offendingLines.isEmpty, "Animate in a Core Animation layer instead; see WorkingSpinner:\n\(offendingLines.joined(separator: "\n"))")
    }

    /// Within rounding of a channel, as antialiasing and color management round the solid stroke.
    private func matches(_ color: UInt32, _ reference: UInt32) -> Bool {
        [16, 8, 0].allSatisfy { shift in abs(Int((color >> shift) & 0xFF) - Int((reference >> shift) & 0xFF)) <= 6 }
    }
}
