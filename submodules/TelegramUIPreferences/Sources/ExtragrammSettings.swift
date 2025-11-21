import Foundation
import Postbox
import SwiftSignalKit
import TelegramCore

public struct ExtragrammSettings: Equatable, Codable {
    public var showTranslateButton: Bool
    public var translateChatsCompletely: Bool
    public var disableNumberRounding: Bool
    public var timeWithSeconds: Bool
    public var showProfileId: Bool
    public var ghostSuppressTyping: Bool
    public var ghostSuppressOnline: Bool
    public var ghostUseScheduling: Bool

    public static var defaultSettings: ExtragrammSettings {
        return ExtragrammSettings(
            showTranslateButton: true,
            translateChatsCompletely: false,
            disableNumberRounding: false,
            timeWithSeconds: false,
            showProfileId: false,
            ghostSuppressTyping: false,
            ghostSuppressOnline: false,
            ghostUseScheduling: true
        )
    }

    public func withUpdatedShowTranslateButton(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.showTranslateButton = value
        return copy
    }

    public func withUpdatedTranslateChatsCompletely(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.translateChatsCompletely = value
        return copy
    }

    public func withUpdatedDisableNumberRounding(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.disableNumberRounding = value
        return copy
    }

    public func withUpdatedTimeWithSeconds(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.timeWithSeconds = value
        return copy
    }

    public func withUpdatedShowProfileId(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.showProfileId = value
        return copy
    }

    public func withUpdatedGhostSuppressTyping(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.ghostSuppressTyping = value
        return copy
    }

    public func withUpdatedGhostSuppressOnline(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.ghostSuppressOnline = value
        return copy
    }

    public func withUpdatedGhostUseScheduling(_ value: Bool) -> ExtragrammSettings {
        var copy = self
        copy.ghostUseScheduling = value
        return copy
    }
}

// Global runtime flag to allow formatting utilities to read the preference without plumbing context.
public enum ExtragrammRuntime {
    public static var timeWithSeconds: Bool = false
    public static var ghostSuppressTyping: Bool = false
    public static var ghostSuppressOnline: Bool = false
    public static var ghostUseScheduling: Bool = true
}

public func updateExtragrammSettingsInteractively(accountManager: AccountManager<TelegramAccountManagerTypes>, _ f: @escaping (ExtragrammSettings) -> ExtragrammSettings) -> Signal<Void, NoError> {
    return accountManager.transaction { transaction -> Void in
        transaction.updateSharedData(ApplicationSpecificSharedDataKeys.extragrammSettings, { entry in
            let current: ExtragrammSettings
            if let entry = entry?.get(ExtragrammSettings.self) {
                current = entry
            } else {
                current = ExtragrammSettings.defaultSettings
            }
            return SharedPreferencesEntry(f(current))
        })
    }
}
