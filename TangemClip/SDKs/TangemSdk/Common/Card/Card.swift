//
//  Card.swift
//  TangemSdk
//
//  Created by Andrew Son on 18/11/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

///Response for `ReadCommand`. Contains detailed card information.
public struct Card: JSONStringConvertible {
	/// Unique Tangem card ID number.
	public let cardId: String?
	/// Name of Tangem card manufacturer.
	public let manufacturerName: String?
	/// Current status of the card.
	public var status: CardStatus?
	/// Version of Tangem COS.
	public let firmwareVersion: FirmwareVersion?
	/// Public key that is used to authenticate the card against manufacturer’s database.
	/// It is generated one time during card manufacturing.
	public let cardPublicKey: Data?
	/// Card settings defined by personalization (bit mask: 0 – Enabled, 1 – Disabled).
	public let settingsMask: SettingsMask?
	/// Public key that is used by the card issuer to sign IssuerData field.
	public let issuerPublicKey: Data?
	/// Defines what data should be submitted to SIGN command.
	public let signingMethods: SigningMethod?
	/// Delay in centiseconds before COS executes commands protected by PIN2. This is a security delay value
	public let pauseBeforePin2: Int?
	/// Any non-zero value indicates that the card experiences some hardware problems.
	/// User should withdraw the value to other blockchain wallet as soon as possible.
	/// Non-zero Health tag will also appear in responses of all other commands.
	public let health: Int?
	/// Whether the card requires issuer’s confirmation of activation
	public let isActivated: Bool
	/// A random challenge generated by personalisation that should be signed and returned
	/// to COS by the issuer to confirm the card has been activated.
	/// This field will not be returned if the card is activated
	public let activationSeed: Data?
	/// Returned only if `SigningMethod.SignPos` enabling POS transactions is supported by card
	public let paymentFlowVersion: Data?
	/// This value can be initialized by terminal and will be increased by COS on execution of every `SignCommand`.
	/// For example, this field can store blockchain “nonce" for quick one-touch transaction on POS terminals.
	/// Returned only if `SigningMethod.SignPos`  enabling POS transactions is supported by card.
	public let userCounter: Int?
	/// When this value is true, it means that the application is linked to the card,
	/// and COS will not enforce security delay if `SignCommand` will be called
	/// with `TlvTag.TerminalTransactionSignature` parameter containing a correct signature of raw data
	/// to be signed made with `TlvTag.TerminalPublicKey`.
	public let terminalIsLinked: Bool
	/// Detailed information about card contents. Format is defined by the card issuer.
	/// Cards complaint with Tangem Wallet application should have TLV format.
	public let cardData: CardData?
	
	/// Set by ScanTask
	public var isPin1Default: Bool? = nil
	/// Set by ScanTask
	public var isPin2Default: Bool? = nil
	
	/// Available only for cards with COS v.4.0 and higher.
	public var pin2IsDefault: Bool? = nil
	
	/// Index of corresponding wallet
	public var walletIndex: Int? = nil
	/// Maximum number of wallets that can be created for this card
	public var walletsCount: Int? = nil
    
    private(set) public var wallets: [CardWallet] = []
    
    internal let defaultCurve: EllipticCurve?
	
	public init(cardId: String?, manufacturerName: String?, status: CardStatus?, firmwareVersion: String?, cardPublicKey: Data?, settingsMask: SettingsMask?, issuerPublicKey: Data?, defaultCurve: EllipticCurve?, signingMethods: SigningMethod?, pauseBeforePin2: Int?, health: Int?, isActivated: Bool, activationSeed: Data?, paymentFlowVersion: Data?, userCounter: Int?, terminalIsLinked: Bool, cardData: CardData?, challenge: Data? = nil, salt: Data? = nil, walletIndex: Int? = nil, walletsCount: Int? = nil) {
		self.cardId = cardId
		self.manufacturerName = manufacturerName
		self.status = status
		self.cardPublicKey = cardPublicKey
		self.settingsMask = settingsMask
		self.issuerPublicKey = issuerPublicKey
		self.signingMethods = signingMethods
		self.pauseBeforePin2 = pauseBeforePin2
		self.health = health
		self.isActivated = isActivated
		self.activationSeed = activationSeed
		self.paymentFlowVersion = paymentFlowVersion
		self.userCounter = userCounter
		self.terminalIsLinked = terminalIsLinked
		self.cardData = cardData
		self.walletIndex = walletIndex
		self.walletsCount = walletsCount
		
		if let version = firmwareVersion {
			self.firmwareVersion = FirmwareVersion(version: version)
		} else {
			self.firmwareVersion = nil
		}
        
        self.defaultCurve = defaultCurve
	}
    
    public mutating func setWallets(_ wallets: [CardWallet]) {
        self.wallets = wallets.sorted(by: { $0.index < $1.index })
    }
    
    public func wallet(at index: WalletIndex) -> CardWallet? {
        switch index {
        case .index(let int):
            return wallets.first(where: { $0.index == int })
        case .publicKey(let pubkey):
            return wallets.first(where: { $0.publicKey == pubkey })
        }
    }
    
    public mutating func updateWallet(at index: WalletIndex, with wallet: CardWallet) {
        guard let index = wallets.firstIndex(where: { $0.index == wallet.index }) else {
            return
        }
        
        wallets[index] = wallet
    }
}

public extension Card {
	
	var firmwareVersionValue: Double? {
		firmwareVersion?.versionDouble
	}
	
	var isLinkedTerminalSupported: Bool {
		return settingsMask?.contains(SettingsMask.skipSecurityDelayIfValidatedByLinkedTerminal) ?? false
	}
	
	var cardType: FirmwareType {
		return firmwareVersion?.type ?? .special
	}
}
