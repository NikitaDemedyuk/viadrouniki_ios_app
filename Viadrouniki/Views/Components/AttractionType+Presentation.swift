import SwiftUI

extension AttractionType {
    /// The API's `color` string (e.g. "rgb(1,185,188)") as a `Color`, or nil if
    /// it's absent or not in that form — callers pick their own fallback.
    var parsedColor: Color? {
        Color(rgbString: color)
    }

    /// The API's `icon` field names a react-icon glyph (e.g. "md:MdOutlineChurch"),
    /// which has no SwiftUI/SF Symbol equivalent, so this is a hand-picked
    /// approximation keyed by `slug` for decorative use only (e.g. filter rows).
    var sfSymbolName: String {
        switch slug {
        case "church": "cross.fill"
        case "cathedral": "building.columns.fill"
        case "basilica": "building.2.fill"
        case "castle": "shield.fill"
        case "ruins": "square.dashed"
        case "monument": "flag.fill"
        case "museum": "paintpalette.fill"
        case "cemetery": "cross.circle.fill"
        case "estate": "house.fill"
        case "nature": "tree.fill"
        case "activity": "bicycle"
        case "azs": "fuelpump.fill"
        case "cafe": "cup.and.saucer.fill"
        default: "mappin"
        }
    }
}

private extension Color {
    init?(rgbString: String?) {
        guard let rgbString,
              rgbString.hasPrefix("rgb("), rgbString.hasSuffix(")")
        else { return nil }
        let components = rgbString
            .dropFirst(4)
            .dropLast()
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard components.count == 3 else { return nil }
        self = Color(
            red: components[0] / 255,
            green: components[1] / 255,
            blue: components[2] / 255
        )
    }
}
