import SwiftUI

/// Above a tab's terminal once its CLI has ended: how it ended and, for a remote tab, a way to check the host, as
/// when its session failed to resume, and to connect again.
struct TerminalEndedBar: View {
    let exitCode: Int32?
    let onCheckHost: (() -> Void)?
    let onReconnect: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let exitCode { Text("Exited (\(exitCode))") }
                else { Text("Ended") }
            }
            .font(ThemeFont.caption)
            .foregroundStyle(ThemePalette.secondaryText)
            Spacer()
            if let onCheckHost {
                Button("Check host", systemImage: "stethoscope", action: onCheckHost)
                    .buttonStyle(QuietBorderedButtonStyle())
                    .controlSize(.small)
                    .help("Check what on the host could have ended this tab, such as its CLI or its folder")
            }
            if let onReconnect {
                Button("Reconnect", systemImage: "arrow.triangle.2.circlepath", action: onReconnect)
                    .buttonStyle(QuietBorderedButtonStyle())
                    .controlSize(.small)
                    .help("Connect again; a CLI still running in tmux on the host is reattached")
            }
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 32)
        .background(ThemePalette.contentSurface)
    }
}
