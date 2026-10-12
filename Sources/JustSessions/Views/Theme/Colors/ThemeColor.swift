import AppKit
import SwiftUI

/// One of the theme's colors, drawn in the theme and the light or dark appearance of the view that uses it. So a view
/// can show a theme other than the window's, as the thumbnails in Settings do.
struct ThemeColor: ShapeStyle {
    enum Role: Sendable {
        case sidebarSurface
        case contentSurface
        case raisedSurface
        case userMessageSurface
        case ink
        case inkForeground
        case secondaryText
        case tertiaryText
        case warningText
        case errorText
        /// Text in a CLI's hue.
        case providerText(ConversationProvider)
        case line
        /// A selected sidebar row's background, washed in its CLI's hue, or in the ink when nil.
        case selectedRow(ConversationProvider?)
        case tabGroup(Int)
        case terminalForeground
        /// One of the terminal's 16 ANSI colors, by its index.
        case terminalANSI(Int)
    }

    let role: Role
    var opacity: Double = 1

    func resolve(in environment: EnvironmentValues) -> Color.Resolved {
        let hexValue = hexValue(in: environment.appTheme.colors(isDark: environment.colorScheme == .dark))
        return Color(
            .sRGB,
            red: Double((hexValue >> 16) & 0xFF) / 255,
            green: Double((hexValue >> 8) & 0xFF) / 255,
            blue: Double(hexValue & 0xFF) / 255,
            opacity: opacity
        )
        .resolve(in: environment)
    }

    /// The color for AppKit drawing, such as the transcript's text views, in `theme`'s light or dark colors.
    func nsColor(in theme: ResolvedAppTheme, isDark: Bool) -> NSColor {
        let hexValue = hexValue(in: theme.colors(isDark: isDark))
        return NSColor(
            srgbRed: CGFloat((hexValue >> 16) & 0xFF) / 255,
            green: CGFloat((hexValue >> 8) & 0xFF) / 255,
            blue: CGFloat(hexValue & 0xFF) / 255,
            alpha: opacity
        )
    }

    private func hexValue(in colors: AppThemeColors) -> UInt32 {
        switch role {
        case .sidebarSurface: colors.sidebarSurface
        case .contentSurface: colors.contentSurface
        case .raisedSurface: colors.raisedSurface
        case .userMessageSurface: colors.userMessageSurface
        case .ink: colors.ink
        case .inkForeground: colors.inkForeground
        case .secondaryText: colors.secondaryText
        case .tertiaryText: colors.tertiaryText
        case .warningText: colors.warningText
        case .errorText: colors.errorText
        case .providerText(let provider): colors.providerTextHexColors[provider, default: colors.ink]
        case .line: colors.line
        case .selectedRow(let provider): colors.selectedRowSurfaces[provider, default: colors.sidebarSurface]
        case .tabGroup(let index): colors.tabGroupHexColors[index]
        case .terminalForeground: colors.terminal.foreground
        case .terminalANSI(let index): colors.terminal.ansiHexColors[index]
        }
    }
}
