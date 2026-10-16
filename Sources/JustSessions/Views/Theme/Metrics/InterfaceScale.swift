import SwiftUI

/// Sizes the interface size scales; see `InterfaceSizeStore`. A view reads them where it would write a number, such
/// as a row's height or an icon button's frame, so text that grows with `ThemeFont` still fits. Spacing between views
/// stays as it is.
@MainActor
enum InterfaceScale {
    static var factor: CGFloat { factor(of: .shared) }

    /// Reading `store`'s scale here, inside a view's body, is what makes the view redraw when it changes. Tests pass a
    /// store of their own, so they never change the size other tests draw at.
    static func factor(of store: InterfaceSizeStore) -> CGFloat {
        CGFloat(store.scale)
    }

    /// `points` at the interface size, rounded to the nearest half point so edges stay sharp.
    static func points(_ points: CGFloat) -> CGFloat {
        self.points(points, at: factor)
    }

    static func points(_ points: CGFloat, at factor: CGFloat) -> CGFloat {
        (points * factor * 2).rounded() / 2
    }

    /// The size of the system's own controls, such as pop-up buttons, sliders, and fields, nearest the interface size.
    static var controlSize: ControlSize { controlSize(at: factor) }

    /// Small below the default size, regular at it and at 110%, large from 120%, and extra large from 140%.
    static func controlSize(at factor: CGFloat) -> ControlSize {
        switch factor {
        case ..<0.95: .small
        case ..<1.15: .regular
        case ..<1.35: .large
        default: .extraLarge
        }
    }
}
