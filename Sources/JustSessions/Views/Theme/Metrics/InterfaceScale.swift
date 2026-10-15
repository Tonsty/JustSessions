import SwiftUI

/// Sizes the interface size scales; see `InterfaceSizeStore`. A view reads them where it would write a number, such
/// as a row's height or an icon button's frame, so text that grows with `ThemeFont` still fits. Spacing between views
/// stays as it is.
@MainActor
enum InterfaceScale {
    static var factor: CGFloat { CGFloat(InterfaceSizeStore.shared.scale) }

    /// `points` at the interface size, rounded to the nearest half point so edges stay sharp.
    static func points(_ points: CGFloat) -> CGFloat {
        (points * factor * 2).rounded() / 2
    }

    /// The size of the system's own controls, such as pop-up buttons, sliders, and fields, nearest the interface size:
    /// small below it, regular at it and at 110%, large from 120%, and extra large from 140%.
    static var controlSize: ControlSize {
        switch factor {
        case ..<0.95: .small
        case ..<1.15: .regular
        case ..<1.35: .large
        default: .extraLarge
        }
    }
}
