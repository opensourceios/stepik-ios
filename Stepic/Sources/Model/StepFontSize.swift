import Foundation

enum StepFontSize: Int, CaseIterable, UniqueIdentifiable {
    case small
    case medium
    case large

    var uniqueIdentifier: UniqueIdentifierType { "\(self.rawValue)" }

    var title: String {
        switch self {
        case .small:
            return NSLocalizedString("SettingsStepFontSizeItemSmall", comment: "")
        case .medium:
            return NSLocalizedString("SettingsStepFontSizeItemMedium", comment: "")
        case .large:
            return NSLocalizedString("SettingsStepFontSizeItemLarge", comment: "")
        }
    }

    // swiftlint:disable:next identifier_name
    var h1: String {
        switch self {
        case .small:
            return "20pt"
        case .medium:
            return "22pt"
        case .large:
            return "24pt"
        }
    }

    // swiftlint:disable:next identifier_name
    var h2: String {
        switch self {
        case .small:
            return "17pt"
        case .medium:
            return "19pt"
        case .large:
            return "21pt"
        }
    }

    // swiftlint:disable:next identifier_name
    var h3: String {
        switch self {
        case .small:
            return "14pt"
        case .medium:
            return "16pt"
        case .large:
            return "18pt"
        }
    }

    var body: String {
        switch self {
        case .small:
            return "12pt"
        case .medium:
            return "14pt"
        case .large:
            return "16pt"
        }
    }

    var blockquote: String {
        switch self {
        case .small:
            return "16px"
        case .medium:
            return "18px"
        case .large:
            return "20px"
        }
    }

    init?(uniqueIdentifier: UniqueIdentifierType) {
        if let value = Int(uniqueIdentifier),
           let fontSize = StepFontSize(rawValue: value) {
            self = fontSize
        } else {
            return nil
        }
    }
}
