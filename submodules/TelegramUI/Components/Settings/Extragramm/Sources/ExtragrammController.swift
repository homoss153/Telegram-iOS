import Foundation
import UIKit
import Display
import AsyncDisplayKit
import TelegramCore
import SwiftSignalKit
import TelegramPresentationData
import AccountContext
import ItemListUI


class ExtragrammBaseController: ViewController {
    let context: AccountContext
    var presentationData: PresentationData
    private var disposable: Disposable?

    private final class Node: ASDisplayNode {
        init(theme: PresentationTheme) {
            super.init()
            self.backgroundColor = theme.list.plainBackgroundColor
        }
    }
    init(context: AccountContext, title: String) {
        self.context = context
        self.presentationData = context.sharedContext.currentPresentationData.with { $0 }
        super.init(navigationBarPresentationData: NavigationBarPresentationData(presentationData: self.presentationData))
        self.title = title
        self.statusBar.statusBarStyle = self.presentationData.theme.rootController.statusBarStyle.style
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: self.presentationData.strings.Common_Back, style: .plain, target: nil, action: nil)
        self.disposable = (context.sharedContext.presentationData
        |> deliverOnMainQueue).start(next: { [weak self] pd in
            guard let self else { return }
            self.presentationData = pd
            self.navigationBar?.updatePresentationData(NavigationBarPresentationData(presentationData: pd))
            self.statusBar.statusBarStyle = pd.theme.rootController.statusBarStyle.style
        })
    }

    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    deinit { self.disposable?.dispose() }

    public override func loadDisplayNode() {
        self.displayNode = Node(theme: self.presentationData.theme)
        self.displayNodeDidLoad()
    }

    public override func containerLayoutUpdated(_ layout: ContainerViewLayout, transition: ContainedViewLayoutTransition) {
        super.containerLayoutUpdated(layout, transition: transition)
        self.displayNode.frame = CGRect(origin: .zero, size: layout.size)
    }
}

final class ExtragrammGeneralController: ExtragrammBaseController {
    init(context: AccountContext) { super.init(context: context, title: "Основное") }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ExtragrammAppearanceController: ExtragrammBaseController {
    init(context: AccountContext) { super.init(context: context, title: "Оформление") }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ExtragrammChatsController: ExtragrammBaseController {
    init(context: AccountContext) { super.init(context: context, title: "Чаты") }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// final class ExtragrammGhostModeController: ExtragrammBaseController {
//     init(context: AccountContext) { super.init(context: context, title: "Режим призрака") }
//     required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
// }

final class ExtragrammSpyController: ExtragrammBaseController {
    init(context: AccountContext) { super.init(context: context, title: "Шпион") }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

final class ExtragrammOtherController: ExtragrammBaseController {
    init(context: AccountContext) { super.init(context: context, title: "Другое") }
    required init(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - ItemList-based main screen

// Колбэки для открытия подэкранов из главного списка Extragramm
private final class ExtragrammListArguments {
    let openGeneral: () -> Void
    let openAppearance: () -> Void
    let openChats: () -> Void
    let openGhost: () -> Void
    let openSpy: () -> Void
    let openOther: () -> Void
    init(openGeneral: @escaping () -> Void, openAppearance: @escaping () -> Void, openChats: @escaping () -> Void, openGhost: @escaping () -> Void, openSpy: @escaping () -> Void, openOther: @escaping () -> Void) {
        self.openGeneral = openGeneral
        self.openAppearance = openAppearance
        self.openChats = openChats
        self.openGhost = openGhost
        self.openSpy = openSpy
        self.openOther = openOther
    }
}

// Entries главного экрана Extragramm (Disclosure-пункты)
private enum ExtragrammEntry: ItemListNodeEntry {
    case general
    case appearance
    case chats
    case ghost
    case spy
    case other

    var section: ItemListSectionId { return 0 }
    var stableId: Int32 {
        switch self {
        case .general: return 0
        case .appearance: return 1
        case .chats: return 2
        case .ghost: return 3
        case .spy: return 4
        case .other: return 5
        }
    }
    static func < (lhs: ExtragrammEntry, rhs: ExtragrammEntry) -> Bool { lhs.stableId < rhs.stableId }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ExtragrammListArguments
        switch self {
        case .general:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.devices, title: "Основное", label: "", sectionId: self.section, style: .blocks, action: { args.openGeneral() })
        case .appearance:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.notifications, title: "Оформление", label: "", sectionId: self.section, style: .blocks, action: { args.openAppearance() })
        case .chats:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.chatFolders, title: "Чаты", label: "", sectionId: self.section, style: .blocks, action: { args.openChats() })
        case .ghost:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.proxy, title: "Режим призрака", label: "", sectionId: self.section, style: .blocks, action: { args.openGhost() })
        case .spy:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.savedMessages, title: "Шпион", label: "", sectionId: self.section, style: .blocks, action: { args.openSpy() })
        case .other:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesSettings.recentCalls, title: "Другое", label: "", sectionId: self.section, style: .blocks, action: { args.openOther() })
        }
    }
}

// Главный экран Extragramm на ItemListController
// controllerRef нужен, чтобы пушить подпункты в текущий стек навигации этого же контроллера
public func extragrammController(context: AccountContext) -> ViewController {
    weak var controllerRef: ItemListController?
    let arguments = ExtragrammListArguments(
        openGeneral: { [weak context] in if let context, let controller = controllerRef { controller.push(ExtragrammBaseController.extragrammGeneralController(context: context)) } },
        openAppearance: { [weak context] in if let context, let controller = controllerRef { controller.push(ExtragrammAppearanceController(context: context)) } },
        openChats: { [weak context] in if let context, let controller = controllerRef { controller.push(ExtragrammChatsController(context: context)) } },
        openGhost: { [weak context] in if let context, let controller = controllerRef { controller.push(ExtragrammBaseController.extragrammGhostModeController(context: context)) } },
        openSpy: { [weak context] in if let context, let controller = controllerRef { controller.push(ExtragrammSpyController(context: context)) } },
        openOther: { [weak context] in if let context, let controller = controllerRef { controller.push(ExtragrammOtherController(context: context)) } }
    )

    let presentationData = context.sharedContext.currentPresentationData.with { $0 }
    let updatedPresentationData = context.sharedContext.presentationData |> map { ItemListPresentationData($0) }

    // Сигнал состояния главного экрана: только presentationData + статический список entries
    let state: Signal<(ItemListControllerState, (ItemListNodeState, ExtragrammListArguments)), NoError> = (context.sharedContext.presentationData
    |> map { presentationData in
        // Параметры контроллера (заголовок, back-кнопка)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Настройки extraGram"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back),
            animateChanges: false
        )
        let entries: [ExtragrammEntry] = [.general, .appearance, .chats, .ghost, .spy, .other]
        // Состояние списка: disclosure-пункты, стиль — блоки
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            ensureVisibleItemTag: nil,
            animateChanges: false
        )
        return (controllerState, (listState, arguments))
    }
    |> deliverOnMainQueue)

    let controller = ItemListController(
        presentationData: ItemListPresentationData(presentationData),
        updatedPresentationData: updatedPresentationData,
        state: state,
        tabBarItem: nil,
        hideNavigationBarBackground: false
    )
    controllerRef = controller
    return controller
}
