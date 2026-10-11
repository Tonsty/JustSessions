import SwiftUI

/// One choice in a `ThemeSegmentedPicker`: the value it picks and the text it shows.
struct ThemeSegment<Value: Hashable> {
    let value: Value
    let title: Text
}
