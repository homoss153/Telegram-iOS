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

// MARK: - Режим призрака: блокировка активностей ввода
extension ExtragrammBaseController {    
    // Аргументы-колбэки для свитчей экрана «Режим призрака»
    final class ExtragrammGhostArguments {
        let updateSuppressTyping: (Bool) -> Void
        let updateSuppressOnline: (Bool) -> Void
        let updateUseScheduling: (Bool) -> Void
        init(updateSuppressTyping: @escaping (Bool) -> Void, updateSuppressOnline: @escaping (Bool) -> Void, updateUseScheduling: @escaping (Bool) -> Void) {
            self.updateSuppressTyping = updateSuppressTyping
            self.updateSuppressOnline = updateSuppressOnline
            self.updateUseScheduling = updateUseScheduling
        }
    }

    // Секции
    enum ExtragrammGhostSection: Int32 {
        case input
    }

    // Entries: заголовок + свитч
    enum ExtragrammGhostEntry: ItemListNodeEntry {
        case inputHeader(String)
        case suppressTyping(Bool)
        case suppressOnline(Bool)
        case useScheduling(Bool)

        var section: ItemListSectionId {
            switch self {
            case .inputHeader, .suppressTyping, .suppressOnline, .useScheduling:
                return ExtragrammGhostSection.input.rawValue
            }
        }
        var stableId: Int32 {
            switch self {
            case .inputHeader: return 0
            case .suppressTyping: return 1
            case .suppressOnline: return 2
            case .useScheduling: return 3
            }
        }
        static func < (lhs: ExtragrammGhostEntry, rhs: ExtragrammGhostEntry) -> Bool { lhs.stableId < rhs.stableId }

        func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
            let args = arguments as! ExtragrammGhostArguments
            switch self {
            case let .inputHeader(text):
                return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
            case let .suppressTyping(value):
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    systemStyle: .glass,
                    title: "Не отправлять \"печатает\"",
                    value: value,
                    sectionId: self.section,
                    style: .blocks,
                    updated: { updatedValue in
                        args.updateSuppressTyping(updatedValue)
                    }
                )
            case let .suppressOnline(value):
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    systemStyle: .glass,
                    title: "Не отправлять онлайн-статус",
                    value: value,
                    sectionId: self.section,
                    style: .blocks,
                    updated: { updatedValue in
                        args.updateSuppressOnline(updatedValue)
                    }
                )
            case let .useScheduling(value):
                return ItemListSwitchItem(
                    presentationData: presentationData,
                    systemStyle: .glass,
                    title: "Использовать отложку (+11 сек)",
                    value: value,
                    sectionId: self.section,
                    style: .blocks,
                    updated: { updatedValue in
                        args.updateUseScheduling(updatedValue)
                    }
                )
            }
        }
    }

    // Фабрика entries для списка Ghost Mode
    static func extragrammGhostEntries(suppressTyping: Bool, suppressOnline: Bool, useScheduling: Bool) -> [ExtragrammGhostEntry] {
        return [
            .inputHeader("Режим призрака"),
            .suppressTyping(suppressTyping),
            .suppressOnline(suppressOnline),
            .useScheduling(useScheduling)
        ]
    }

    // Контроллер экрана «Режим призрака» в стиле General
    public static func extragrammGhostModeController(context: AccountContext) -> ViewController {
        let settingsSignal: Signal<ExtragrammSettings, NoError> = context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.extragrammSettings])
        |> map { view in
            let data = view.entries[ApplicationSpecificSharedDataKeys.extragrammSettings]?.get(ExtragrammSettings.self)
            return data ?? ExtragrammSettings.defaultSettings
        }

        let arguments = ExtragrammGhostArguments(
            updateSuppressTyping: { value in
                ExtragrammRuntime.ghostSuppressTyping = value
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedGhostSuppressTyping(value) }).start()
            },
            updateSuppressOnline: { value in
                ExtragrammRuntime.ghostSuppressOnline = value
                ExtragrammCoreRuntime.ghostSuppressOnline = value
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedGhostSuppressOnline(value) }).start()
            },
            updateUseScheduling: { value in
                ExtragrammRuntime.ghostUseScheduling = value
                _ = updateExtragrammSettingsInteractively(accountManager: context.sharedContext.accountManager, { $0.withUpdatedGhostUseScheduling(value) }).start()
            }
        )

        let signal: Signal<(ItemListControllerState, (ItemListNodeState, ExtragrammGhostArguments)), NoError> = combineLatest(
            context.sharedContext.presentationData,
            settingsSignal
        )
        |> deliverOnMainQueue
        |> map { (presentationData: PresentationData, settings: ExtragrammSettings) in
            // Синхронизируем рантайм
            ExtragrammRuntime.ghostSuppressTyping = settings.ghostSuppressTyping
            ExtragrammRuntime.ghostSuppressOnline = settings.ghostSuppressOnline
            ExtragrammRuntime.ghostUseScheduling = settings.ghostUseScheduling
            ExtragrammCoreRuntime.ghostSuppressOnline = settings.ghostSuppressOnline

            let controllerState = ItemListControllerState(
                presentationData: ItemListPresentationData(presentationData),
                title: .text("Режим призрака"),
                leftNavigationButton: nil,
                rightNavigationButton: nil,
                backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
                animateChanges: false
            )
            let listState = ItemListNodeState(
                presentationData: ItemListPresentationData(presentationData),
                entries: Self.extragrammGhostEntries(suppressTyping: settings.ghostSuppressTyping, suppressOnline: settings.ghostSuppressOnline, useScheduling: settings.ghostUseScheduling),
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
