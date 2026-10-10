import SwiftUI

/// A segmented control in the theme's colors. The system one marks its selected segment with a gray that barely
/// differs from its track on dark theme surfaces, so here the selected segment is filled with the ink, like a checked
/// `ThemedCheckboxToggleStyle` box. It fills the width it is offered; use `.fixedSize()` to fit its titles.
struct ThemeSegmentedPicker<Value: Hashable>: View {
    /// Not shown; VoiceOver reads it as the control's label.
    let accessibilityTitle: LocalizedStringKey
    @Binding var selection: Value
    let segments: [ThemeSegment<Value>]

    init(_ accessibilityTitle: LocalizedStringKey, selection: Binding<Value>, segments: [ThemeSegment<Value>]) {
        self.accessibilityTitle = accessibilityTitle
        _selection = selection
        self.segments = segments
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(segments, id: \.value) { segment in
                segmentButton(segment)
            }
        }
        .padding(2)
        .background(ThemePalette.trackFill, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
        .accessibilityRepresentation {
            Picker(accessibilityTitle, selection: $selection) {
                ForEach(segments, id: \.value) { segment in
                    segment.title.tag(segment.value)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private func segmentButton(_ segment: ThemeSegment<Value>) -> some View {
        let isSelected = segment.value == selection

        return Button {
            selection = segment.value
        } label: {
            segment.title
                .font(.system(size: 13))
                .foregroundStyle(isSelected ? ThemePalette.inkForeground : ThemePalette.secondaryText)
                .lineLimit(1)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(ThemePalette.ink)
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(ThemePlainButtonStyle(cornerRadius: 5))
    }
}
