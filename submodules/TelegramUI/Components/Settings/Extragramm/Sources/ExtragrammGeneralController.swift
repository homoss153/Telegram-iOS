import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import TelegramUIPreferences
import ItemListUI

// MARK: - Основное: Перевод сообщений / Основные / Профиль
extension ExtragrammBaseController {
    // Колбэки для обновления состояний свитчей с экрана «Основное»
    final class ExtragrammGeneralArguments {
        let updateShowButton: (Bool) -> Void
        let updateTranslateChats: (Bool) -> Void
        let updateDisableRounding: (Bool) -> Void
        let updateTimeWithSeconds: (Bool) -> Void
        let updateProfileHideId: (Bool) -> Void
        init(updateShowButton: @escaping (Bool) -> Void, updateTranslateChats: @escaping (Bool) -> Void, updateDisableRounding: @escaping (Bool) -> Void, updateTimeWithSeconds: @escaping (Bool) -> Void, updateProfileHideId: @escaping (Bool) -> Void) {
            self.updateShowButton = updateShowButton
            self.updateTranslateChats = updateTranslateChats
            self.updateDisableRounding = updateDisableRounding
            self.updateTimeWithSeconds = updateTimeWithSeconds
            self.updateProfileHideId = updateProfileHideId
        }
    }

    // Секции экрана «Основное»
    enum ExtragrammGeneralSection: Int32 {
        case translate
        case basics
        case profile
    }

    // Entries описывают элементы списка: заголовки секций + независимые свитчи
    enum ExtragrammGeneralEntry: ItemListNodeEntry {
        case translateHeader(String)
        case showButton(Bool)
        case translateChats(Bool)
        case basicsHeader(String)
        case disableRounding(Bool)
        case timeWithSeconds(Bool)
        case profileHeader(String)
        case profileHideId(Bool)

        var section: ItemListSectionId {
            switch self {
            case .translateHeader, .showButton, .translateChats:
                return ExtragrammGeneralSection.translate.rawValue
            case .basicsHeader, .disableRounding, .timeWithSeconds:
                return ExtragrammGeneralSection.basics.rawValue
            case .profileHeader, .profileHideId:
                return ExtragrammGeneralSection.profile.rawValue
            }
        }
        var stableId: Int32 {
            switch self {
            case .translateHeader: return 0
            case .showButton: return 1
            case .translateChats: return 2
            case .basicsHeader: return 3
            case .disableRounding: return 4
            case .timeWithSeconds: return 5
            case .profileHeader: return 6
            case .profileHideId: return 7
            }
        }
        static func < (lhs: ExtragrammGeneralEntry, rhs: ExtragrammGeneralEntry) -> Bool { lhs.stableId < rhs.stableId }

        func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
            let args = arguments as! ExtragrammGeneralArguments
            switch self {
            case let .translateHeader(text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .showButton(value):
                // Свитч «Показывать кнопку перевести» (независимый)
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Показывать кнопку перевести", value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    args.updateShowButton(updatedValue)
                })
            case let .translateChats(value):
                // Свитч «Переводить чаты целиком» (независимый)
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Переводить чаты целиком", value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    args.updateTranslateChats(updatedValue)
                })
            case let .basicsHeader(text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .disableRounding(value):
                // Свитч «Отключить округление чисел»
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Отключить округление чисел", value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    args.updateDisableRounding(updatedValue)
                })
            case let .timeWithSeconds(value):
                // Свитч «Форматировать время с секундами»
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Форматировать время с секундами", value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    args.updateTimeWithSeconds(updatedValue)
                })
            case let .profileHeader(text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .profileHideId(value):
                // Свитч «Показывать ID в профиле»
                return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: "Показывать ID в профиле", value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                    args.updateProfileHideId(updatedValue)
                })
            }
        }
    }

    // Фабрика entries для построения списка «Основное»
    static func extragrammGeneralEntries(showButton: Bool, translateChats: Bool, disableRounding: Bool, timeWithSeconds: Bool, profileHideId: Bool) -> [ExtragrammGeneralEntry] {
        return [
            .translateHeader("Перевод сообщений"),
            .showButton(showButton),
            .translateChats(translateChats),
            .basicsHeader("Основные"),
            .disableRounding(disableRounding),
            .timeWithSeconds(timeWithSeconds),
            .profileHeader("Профиль"),
            .profileHideId(profileHideId)
        ]
    }

    // Контроллер экрана «Основное» с реактивным состоянием из sharedData (персист)
    static func extragrammGeneralController(context: AccountContext) -> ViewController {
        let settingsSignal: Signal<ExtragrammSettings, NoError> = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.extragrammSettings])
        |> map { view in
            let data = view.entries[ApplicationSpecificSharedDataKeys.extragrammSettings]?.get(ExtragrammSettings.self)
            return data ?? ExtragrammSettings.defaultSettings
        }

        let arguments = ExtragrammGeneralArguments(
            updateShowButton: { value in
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedShowTranslateButton(value) }).start()
            },
            updateTranslateChats: { value in
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedTranslateChatsCompletely(value) }).start()
            },
            updateDisableRounding: { value in
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedDisableNumberRounding(value) }).start()
            },
            updateTimeWithSeconds: { value in
                ExtragrammRuntime.timeWithSeconds = value
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedTimeWithSeconds(value) }).start()
            },
            updateProfileHideId: { value in
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedShowProfileId(value) }).start()
            }
        )

        let signal: Signal<(ItemListControllerState, (ItemListNodeState, ExtragrammGeneralArguments)), NoError> = combineLatest(
            context.sharedContext.presentationData,
            settingsSignal
        )
        |> deliverOnMainQueue
        |> map { (presentationData: PresentationData, settings: ExtragrammSettings) in
            // Keep global runtime flag in sync for formatting utilities
            ExtragrammRuntime.timeWithSeconds = settings.timeWithSeconds
            // Заголовок, back-кнопка и прочие параметры контроллера
            let controllerState = ItemListControllerState(
                presentationData: ItemListPresentationData(presentationData),
                title: .text("Основное"),
                leftNavigationButton: nil,
                rightNavigationButton: nil,
                backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
                animateChanges: false
            )
            // Состояние списка: entries и стиль блоков (как в настройках Telegram)
            let listState = ItemListNodeState(
                presentationData: ItemListPresentationData(presentationData),
                entries: Self.extragrammGeneralEntries(
                    showButton: settings.showTranslateButton,
                    translateChats: settings.translateChatsCompletely,
                    disableRounding: settings.disableNumberRounding,
                    timeWithSeconds: settings.timeWithSeconds,
                    profileHideId: settings.showProfileId
                ),
                style: .blocks,
                ensureVisibleItemTag: nil,
                animateChanges: false
            )
            return (controllerState, (listState, arguments))
        }

        let presentationData = context.sharedContext.currentPresentationData.with { $0 }
        let updatedPresentationData = context.sharedContext.presentationData |> map { ItemListPresentationData($0) }
        let controller = ItemListController(
            presentationData: ItemListPresentationData(presentationData),
            updatedPresentationData: updatedPresentationData,
            state: signal,
            tabBarItem: nil,
            hideNavigationBarBackground: false
        )
        return controller
    }
}
