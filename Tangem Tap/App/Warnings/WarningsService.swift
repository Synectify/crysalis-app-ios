//
//  WarningsService.swift
//  Tangem Tap
//
//  Created by Andrew Son on 22/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import Combine

protocol WarningsConfigurator: class {
    func setupWarnings(for card: Card)
}

protocol WarningAppendor: class {
    func appendWarning(for event: WarningEvent)
}

protocol WarningsManager: WarningAppendor {
    var warningsUpdatePublisher: PassthroughSubject<WarningsLocation, Never> { get }
    func warnings(for location: WarningsLocation) -> WarningsContainer
    func hideWarning(_ warning: TapWarning)
    func hideWarning(for event: WarningEvent)
}

class WarningsService {
    
    var warningsUpdatePublisher: PassthroughSubject<WarningsLocation, Never> = PassthroughSubject()
    private var mainWarnings: WarningsContainer = .init() {
        didSet {
            warningsUpdatePublisher.send(.main)
        }
    }
    private var sendWarnings: WarningsContainer = .init() {
        didSet {
            warningsUpdatePublisher.send(.send)
        }
    }
    
    private let remoteWarningProvider: RemoteWarningProvider
    private let rateAppChecker: RateAppChecker
    
    init(remoteWarningProvider: RemoteWarningProvider, rateAppChecker: RateAppChecker) {
        self.remoteWarningProvider = remoteWarningProvider
        self.rateAppChecker = rateAppChecker
    }
    
    deinit {
        print("WarningsService deinit")
    }
    
    private func warningsForMain(for card: Card) -> WarningsContainer {
        let container = WarningsContainer()
        
        addDevCardWarningIfNeeded(in: container, for: card)
        addLowRemainingSignaturesWarningIfNeeded(in: container, for: card)
        addOldCardWarning(in: container, for: card)
        addOldDeviceOldCardWarningIfNeeded(in: container, for: card)
        if rateAppChecker.shouldShowRateAppWarning {
            Analytics.log(event: .displayRateAppWarning)
            container.add(WarningEvent.rateApp.warning)
        }
        
        let remoteWarnings = self.remoteWarnings(for: card, location: .main)
        container.add(remoteWarnings)
        
        return container
    }
    
    private func warningsForSend(for card: Card) -> WarningsContainer {
        let container = WarningsContainer()
        
        addOldDeviceOldCardWarningIfNeeded(in: container, for: card)
        
        let remoteWarnings = self.remoteWarnings(for: card, location: .send)
        container.add(remoteWarnings)
        
        return container
    }
    
    private func remoteWarnings(for card: Card, location: WarningsLocation) -> [TapWarning] {
        let remoteWarnings = remoteWarningProvider.warnings
        let mainRemoteWarnings = remoteWarnings.filter { $0.location.contains { $0 == location } }
        let cardRemoteWarnings = mainRemoteWarnings.filter {
            $0.blockchains == nil ||
            $0.blockchains?.contains { $0.lowercased() == (card.cardData?.blockchainName ?? "").lowercased() } ?? false
        }
        return cardRemoteWarnings
    }
    
    private func addDevCardWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        guard card.firmwareVersion?.type == .sdk else {
            return
        }
        
        container.add(WarningsList.devCard)
    }
    
    private func addOldCardWarning(in container: WarningsContainer, for card: Card) {
        if card.canSign { return }
        
        container.add(WarningsList.oldCard)
    }
    
    private func addOldDeviceOldCardWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        guard let fw = card.firmwareVersionValue else {
            return
        }
        
        guard fw < 2.28 else { //old cards
            return
        }
        
        guard NfcUtils.isPoorNfcQualityDevice else { //old phone
            return
        }
        
        container.add(WarningsList.oldDeviceOldCard)
    }
    
    private func addLowRemainingSignaturesWarningIfNeeded(in container: WarningsContainer, for card: Card) {
        if let remainingSignatures = card.wallets.first?.remainingSignatures,
           remainingSignatures <= 10 {
            container.add(WarningsList.lowSignatures(count: remainingSignatures))
        }
    }
    
}

extension WarningsService: WarningsManager {
    func warnings(for location: WarningsLocation) -> WarningsContainer {
        switch location {
        case .main:
            return mainWarnings
        case .send:
            return sendWarnings
        }
    }
    
    func appendWarning(for event: WarningEvent) {
        let warning = event.warning
        if event.locationsToDisplay.contains(.main) {
            mainWarnings.add(warning)
        }
        if event.locationsToDisplay.contains(.send) {
            sendWarnings.add(warning)
        }
    }
    
    func hideWarning(_ warning: TapWarning) {
        mainWarnings.remove(warning)
        sendWarnings.remove(warning)
    }
    
    func hideWarning(for event: WarningEvent) {
        mainWarnings.removeWarning(for: event)
        sendWarnings.removeWarning(for: event)
    }
}

extension WarningsService: WarningsConfigurator {
    func setupWarnings(for card: Card) {
        mainWarnings = warningsForMain(for: card)
        sendWarnings = warningsForSend(for: card)
    }
}
