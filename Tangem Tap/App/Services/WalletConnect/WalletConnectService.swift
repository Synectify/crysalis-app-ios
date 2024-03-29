//
//  WalletConnectService.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 22.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import Foundation
import WalletConnectSwift
import Combine
import TangemSdk
import BlockchainSdk
import CryptoSwift
import SwiftUI
import web3swift

protocol WalletConnectChecker: AnyObject {
    var isServiceBusy: CurrentValueSubject<Bool, Never> { get }
    func containSession(for wallet: WalletInfo) -> Bool
}

protocol WalletConnectSessionController: WalletConnectChecker {
    var sessionsPublisher: Published<[WalletConnectSession]>.Publisher { get }
    func disconnectSession(at index: Int)
    func canHandle(url: String) -> Bool
    func handle(url: String) -> Bool
}

protocol WalletConnectHandlerDelegate: AnyObject {
    func send(_ response: Response, for action: WalletConnectAction)
    func sendInvalid(_ request: Request)
    func sendReject(for request: Request, with error: Error, for action: WalletConnectAction)
}

protocol WalletConnectHandlerDataSource: AnyObject {
    var server: Server! { get }
    func session(for request: Request, address: String) -> WalletConnectSession?
}

enum WalletConnectAction: String {
    case personalSign = "personal_sign"
    case signTransaction = "eth_signTransaction"
    case sendTransaction = "eth_sendTransaction"
    
    var successMessage: String {
        switch self {
        case .personalSign: return "wallet_connect_message_signed".localized
        case .signTransaction: return "wallet_connect_transaction_signed".localized
        case .sendTransaction: return "wallet_connect_transaction_signed_and_send".localized
        }
    }
}

class WalletConnectService: ObservableObject {
    var isServiceBusy: CurrentValueSubject<Bool, Never> = .init(false)
    
    @Published private(set) var sessions: [WalletConnectSession] = .init()
    var sessionsPublisher: Published<[WalletConnectSession]>.Publisher { $sessions }
    
    private(set) var server: Server!
    
    fileprivate var wallet: WalletInfo? = nil
    private let sessionsKey = "wc_sessions"
    
    private unowned var cardScanner: WalletConnectCardScanner
    private var bag: Set<AnyCancellable> = []
    private var isWaitingToConnect: Bool = false
    private var timer: Timer?
    
    init(assembly: Assembly, cardScanner: WalletConnectCardScanner, signer: TangemSigner, scannedCardsRepository: ScannedCardsRepository) {
        self.cardScanner = cardScanner
        server = Server(delegate: self)
        server.register(handler: PersonalSignHandler(signer: signer, delegate: self, dataSource: self))
        server.register(handler: SignTransactionHandler(signer: signer, delegate: self, dataSource: self, assembly: assembly, scannedCardsRepo: scannedCardsRepository))
        server.register(handler: SendTransactionHandler(signer: signer, delegate: self, dataSource: self, assembly: assembly, scannedCardsRepo: scannedCardsRepository))
    }
    
    func disconnect(from session: Session) {
        do {
            if let session = sessions.first(where: { $0.session == session }) {
                try server.disconnect(from: session.session)
            }
        } catch {
            handle(WalletConnectServiceError.other(error))
        }
    }
    
    func restore() {
        let decoder = JSONDecoder()
        if let oldSessionsObject = UserDefaults.standard.object(forKey: sessionsKey) as? Data {
            sessions = (try? decoder.decode([WalletConnectSession].self, from: oldSessionsObject)) ?? []
            sessions.forEach {
                do {
                    try server.reconnect(to: $0.session)
                } catch {
                    handle(WalletConnectServiceError.other(error))
                }
            }
        }
    }
    
    private func connect(to url: WCURL) {
        isServiceBusy.send(true)
        cardScanner.scanCard()
            .sink { [unowned self] completion in
                if case let .failure(error) = completion {
                    self.handle(error, delay: 0.5)
                }
            } receiveValue: { [unowned self] wallet in
                self.wallet = wallet
                self.setupSessionConnectTimer()
                do {
                    try self.server.connect(to: url)
                } catch {
                    self.handle(error)
                    self.resetSessionConnectTimer()
                }
            }
            .store(in: &bag)
    }
    
    private func save() {
        let encoder = JSONEncoder()
        if let sessionsData = try? encoder.encode(sessions) {
            UserDefaults.standard.set(sessionsData, forKey: sessionsKey)
        }
    }
    
    private func setupSessionConnectTimer() {
        isWaitingToConnect = true
        isServiceBusy.send(true)
        timer = .scheduledTimer(withTimeInterval: 20, repeats: false, block: { [unowned self] timer in
            self.isWaitingToConnect = false
            self.handle(WalletConnectServiceError.timeout)
        })
    }
    
    private func handle(_ error: Error, for action: WalletConnectAction? = nil, delay: TimeInterval = 0) {
        isServiceBusy.send(false)
        if let wcError = error as? WalletConnectServiceError {
            switch wcError {
            case .cancelled, .deallocated:
                return
            default:
                break
            }
        }
        
        if let tangemError = error as? TangemSdkError, case .userCancelled = tangemError {
            return
        }
        
        Analytics.logWcEvent(.error(error, action))
        presentOnTop(WalletConnectUIBuilder.makeErrorAlert(error), delay: delay)
    }
    
    private func resetSessionConnectTimer() {
        timer?.invalidate()
        isWaitingToConnect = false
    }
    
    private func presentOnTop(_ vc: UIViewController, delay: TimeInterval = 0) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            UIApplication.modalFromTop(vc)
        }
    }
}

extension WalletConnectService: WalletConnectHandlerDataSource {
    func session(for request: Request, address: String) -> WalletConnectSession? {
        sessions.first(where: { $0.wallet.address.lowercased() == address.lowercased() && $0.session.url.topic == request.url.topic })
    }
}

extension WalletConnectService: WalletConnectHandlerDelegate {
    func send(_ response: Response, for action: WalletConnectAction) {
        server.send(response)
        Analytics.logWcEvent(.action(action))
        presentOnTop(WalletConnectUIBuilder.makeAlert(for: .success, message: action.successMessage), delay: 0.5)
    }
    
    func sendInvalid(_ request: Request) {
        Analytics.logWcEvent(.invalidRequest(json: request.jsonString))
        server.send(.invalid(request))
    }
    
    func sendReject(for request: Request, with error: Error, for action: WalletConnectAction) {
        handle(error, for: action)
        server.send(.reject(request))
    }
}

extension WalletConnectService: WalletConnectChecker {
    func containSession(for wallet: WalletInfo) -> Bool {
        sessions.contains(where: { $0.wallet == wallet })
    }
}

extension WalletConnectService: WalletConnectSessionController {
    func disconnectSession(at index: Int) {
        guard index < sessions.count else { return }
        
        let session = sessions[index]
        do {
            try server.disconnect(from: session.session)
        } catch {
            print(error)
        }
        
        sessions.remove(at: index)
        save()
        Analytics.logWcEvent(.session(.disconnect, session.session.dAppInfo.peerMeta.url))
    }
    
    func canHandle(url: String) -> Bool {
        WCURL(url) != nil
    }
}

extension WalletConnectService: ServerDelegate {
    private var walletMeta: Session.ClientMeta {
        Session.ClientMeta(name: "Tangem Wallet",
                           description: nil,
                           icons: [],
                           url: Constants.tangemDomainUrl)
    }
    
    private var rejectedResponse: Session.WalletInfo {
        Session.WalletInfo(approved: false,
                           accounts: [],
                           chainId: 0,
                           peerId: "",
                           peerMeta: walletMeta)
    }
    
    func server(_ server: Server, didFailToConnect url: WCURL) {
        handle(WalletConnectServiceError.failedToConnect)
    }
    
    func server(_ server: Server, shouldStart session: Session, completion: @escaping (Session.WalletInfo) -> Void) {
        guard isWaitingToConnect,
            let wallet = self.wallet else {
            isServiceBusy.send(false)
            completion(rejectedResponse)
            return
        }
        
        resetSessionConnectTimer()
        let peerMeta = session.dAppInfo.peerMeta
        var message = String(format: "wallet_connect_request_session_start".localized, wallet.cid, peerMeta.name, peerMeta.url.absoluteString)
        if let description = peerMeta.description, !description.isEmpty {
            message += "\n\n" + description
        }
        let onAccept = {
            self.sessions.filter {
                $0.wallet == wallet &&
                    $0.session.dAppInfo.peerMeta.url == session.dAppInfo.peerMeta.url
            }.forEach { try? server.disconnect(from: $0.session) }
            completion(Session.WalletInfo(approved: true,
                                          accounts: [wallet.address],
                                          chainId: wallet.chainId,
                                          peerId: UUID().uuidString,
                                          peerMeta: self.walletMeta))
        }
        
        presentOnTop(WalletConnectUIBuilder.makeAlert(for: .establishSession,
                                                      message: message,
                                                      onAcceptAction: onAccept,
                                                      onReject: {
                                                        completion(self.rejectedResponse)
                                                        self.isServiceBusy.send(false)
                                                      }),
                     delay: 0.5)
    }
    
    func server(_ server: Server, didConnect session: Session) {
        if let sessionIndex = sessions.firstIndex(where: { $0.session == session }) { //reconnect
            sessions[sessionIndex].status = .connected
        } else {
            if let wallet = self.wallet { //new session only if wallet exists
                sessions.append(WalletConnectSession(wallet: wallet, session: session, status: .connected))
                save()
                Analytics.logWcEvent(.session(.connect, session.dAppInfo.peerMeta.url))
            }
        }
        isServiceBusy.send(false)
    }
    
    func server(_ server: Server, didDisconnect session: Session) {
        if let index = sessions.firstIndex(where: { $0.session == session }) {
            sessions.remove(at: index)
            save()
        }
    }
}

extension WalletConnectService: URLHandler {
    func handle(url: URL) -> Bool {
        guard let link = extractWcUrl(from: url) else { return false }
        
        return handle(url: link)
    }
    
    func handle(url: String) -> Bool {
        guard let url = WCURL(url) else { return false }
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3, execute: {
            self.connect(to: url)
        })
        
        return true
    }
    
    private func extractWcUrl(from url: URL) -> String? {
        let absoluteStr = url.absoluteString
        if canHandle(url: absoluteStr) {
            return absoluteStr
        }
        
        let uriPrefix = "uri="
        let wcPrefix = "wc:"
        
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
            let scheme = components.scheme,
            var query = components.query
        else { return nil }
        
        guard (absoluteStr.starts(with: Constants.tangemDomain) && query.starts(with: uriPrefix + wcPrefix)) ||
                ((Bundle.main.infoDictionary?["CFBundleURLTypes"] as? [[String:Any]])?.map { $0["CFBundleURLSchemes"] as? [String] }.contains(where: { $0?.contains(scheme) ?? false }) ?? false)
        else { return nil }
        
        query.removeFirst(uriPrefix.count)

        guard canHandle(url: query) else { return nil }
        
        return query
    }
}

enum WalletConnectServiceError: LocalizedError {
    case failedToConnect
    case signFailed
    case cancelled
    case timeout
    case deallocated
    case failedToFindSigner
    case cardNotFound
    case sessionNotFound
    case txNotFound
    case failedToBuildTx
    case other(Error)
    
    var shouldHandle: Bool {
        switch self {
        case .cancelled, .deallocated, .failedToFindSigner: return false
        default: return true
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .timeout: return "wallet_connect_error_timeout".localized
        case .signFailed: return "wallet_connect_error_sing_failed".localized
        case .failedToConnect: return "wallet_connect_error_failed_to_connect".localized
        case .cardNotFound: return "wallet_connect_card_not_found".localized
        case .txNotFound: return "wallet_connect_tx_not_found".localized
        case .sessionNotFound: return "wallet_connect_session_not_found".localized
        case .failedToBuildTx: return "wallet_connect_failed_to_build_tx".localized
        case .other(let error): return error.localizedDescription
        default: return ""
        }
    }
}
