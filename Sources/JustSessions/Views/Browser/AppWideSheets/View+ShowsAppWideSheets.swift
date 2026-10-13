import SwiftUI

extension View {
    /// Shows Settings while `sheet` holds a selected page. Help opens its Help tab in the same sheet. `hosts` are the
    /// window's hosts, whose settings Settings lists.
    func showsAppWideSheets(
        _ sheet: Binding<AppWideSheet?>,
        hosts: [SessionHost],
        onCheckForUpdates: @escaping () -> Void
    ) -> some View {
        environment(\.showAppWideSheet, ShowAppWideSheetAction { sheet.wrappedValue = $0 })
            .background(AppWideSheetWindowRegistration(sheet: sheet))
            .sheet(item: sheet) { _ in
                SettingsSheet(
                    selectedTab: Binding(
                        get: { sheet.wrappedValue?.selectedSettingsTab ?? .general },
                        set: { sheet.wrappedValue = AppWideSheet(selectedSettingsTab: $0) }
                    ),
                    hosts: hosts,
                    onCheckForUpdates: onCheckForUpdates
                )
            }
            .dismissesOnClickOutside(item: sheet)
            .onAppear {
                if let sheetForThisWindow = AppWideSheetPresenters.takeSheetForNewWorkspaceWindow() {
                    sheet.wrappedValue = sheetForThisWindow
                }
            }
    }
}
