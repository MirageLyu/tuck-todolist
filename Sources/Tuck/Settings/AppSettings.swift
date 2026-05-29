import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case zhHans
    case english

    var id: String { rawValue }

    var isChinese: Bool {
        switch self {
        case .zhHans:
            true
        case .english:
            false
        case .system:
            Locale.preferredLanguages.first?.lowercased().hasPrefix("zh") == true
        }
    }

    var shortLabel: String {
        switch self {
        case .system: isChinese ? "系统" : "Auto"
        case .zhHans: "中"
        case .english: "EN"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        let languageValue = defaults.string(forKey: Keys.language) ?? defaults.string(forKey: Keys.legacyLanguage) ?? AppLanguage.english.rawValue
        self.language = AppLanguage(rawValue: languageValue) ?? .english
    }

    var strings: Strings { Strings(language: language) }

    func cycleLanguage() {
        language = next(language, in: AppLanguage.allCases)
    }

    private func next<T: CaseIterable & Equatable>(_ value: T, in values: T.AllCases) -> T where T.AllCases: Collection {
        guard let index = values.firstIndex(of: value) else { return values.first! }
        let nextIndex = values.index(after: index)
        return nextIndex == values.endIndex ? values.first! : values[nextIndex]
    }
}

private enum Keys {
    static let language = "Tuck.language"
    static let legacyLanguage = "TodoAgent.language"
}
