import Foundation
import Postbox
import SwiftSignalKit
import TelegramApi

func _internal_sendReadForMessage(postbox: Postbox, network: Network, index: MessageIndex) -> Signal<Void, NoError> {
    return postbox.transaction { transaction -> (Peer?, MessageIndex) in
        let peer = transaction.getPeer(index.id.peerId)
        return (peer, index)
    }
    |> mapToSignal { peer, index -> Signal<Void, NoError> in
        guard let peer = peer else {
            return .complete()
        }
        if let channel = peer as? TelegramChannel, let inputChannel = apiInputChannel(channel) {
            return network.request(Api.functions.channels.readHistory(channel: inputChannel, maxId: index.id.id))
            |> map { _ in }
            |> `catch` { _ in .complete() }
        } else if let inputPeer = apiInputPeer(peer) {
            return network.request(Api.functions.messages.readHistory(peer: inputPeer, maxId: index.id.id))
            |> map { _ in }
            |> `catch` { _ in .complete() }
        } else if let secretChat = peer as? TelegramSecretChat, let inputEncryptedChat = apiInputSecretChat(secretChat) {
            return network.request(Api.functions.messages.readEncryptedHistory(peer: inputEncryptedChat, maxDate: index.timestamp))
            |> map { _ in }
            |> `catch` { _ in .complete() }
        } else {
            return .complete()
        }
    }
}
