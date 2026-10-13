/// How strongly the terminal's 16 ANSI colors show, set with **Color intensity** in Appearance settings, as a
/// percentage of the scheme's own: more makes each color more vivid, less softer. Each keeps its OKLab lightness and
/// hue and only its chroma scales, so text in it stays as light or dark against the background as the scheme made it.
enum TerminalColorIntensity {
    static let percentRange = 50...200
    static let defaultPercent = 100
    static let percentStep = 5

    /// The color with its chroma scaled to `percent`, as far as sRGB can show it at the same lightness and hue.
    static func adjusted(_ hexValue: UInt32, percent: Int) -> UInt32 {
        guard percent != defaultPercent else { return hexValue }
        let color = OKLabColor(hexValue: hexValue)
        let targetChroma = color.chroma * Double(percent) / 100
        let target = color.withChroma(targetChroma)
        if target.isInSRGB { return target.hexValue }
        // Past what sRGB shows, the most it shows: between the color's own chroma, which it shows, and the target.
        var shownChroma = color.chroma
        var unshownChroma = targetChroma
        for _ in 0..<24 {
            let middleChroma = (shownChroma + unshownChroma) / 2
            if color.withChroma(middleChroma).isInSRGB { shownChroma = middleChroma } else { unshownChroma = middleChroma }
        }
        return color.withChroma(shownChroma).hexValue
    }
}
