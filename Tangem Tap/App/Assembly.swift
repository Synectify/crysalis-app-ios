//
//  Assembly.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 03.11.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import TangemSdk
import BlockchainSdk

class ServicesAssembly {
    weak var assembly: Assembly!
    lazy var urlHandlers: [URLHandler] = [
        walletConnectService
    ]
    
    deinit {
        print("ServicesAssembly deinit")
    }
    
    let logger = Logger()
    lazy var navigationCoordinator = NavigationCoordinator()
    lazy var ratesService = CoinMarketCapService(apiKey: keysManager.coinMarketKey)
    lazy var userPrefsService = UserPrefsService()
    lazy var networkService = NetworkService()
    lazy var walletManagerFactory = WalletManagerFactory(config: keysManager.blockchainConfig)
    lazy var featuresService = AppFeaturesService(configProvider: configManager)
    lazy var warningsService = WarningsService(remoteWarningProvider: configManager, rateAppChecker: rateAppService)
    lazy var persistentStorage = PersistentStorage()
    lazy var tokenItemsRepository = TokenItemsRepository(persistanceStorage: persistentStorage)
    lazy var keychainService = ValidatedCardsService()
    lazy var imageLoaderService: CardImageLoaderService = CardImageLoaderService(networkService: networkService)
    lazy var rateAppService: RateAppService = .init(userPrefsService: userPrefsService)
    lazy var topupService: TopupService = .init(keys: keysManager.moonPayKeys)
    lazy var tangemSdk: TangemSdk = .init()
    lazy var walletConnectService = WalletConnectService(assembly: assembly, cardScanner: walletConnectCardScanner, signer: signer, scannedCardsRepository: scannedCardsRepository)
    
    lazy var negativeFeedbackDataCollector: NegativeFeedbackDataCollector = {
        let collector = NegativeFeedbackDataCollector()
        collector.cardRepository = cardsRepository
        return collector
    }()
    
    lazy var failedCardScanTracker: FailedCardScanTracker = {
        let tracker = FailedCardScanTracker()
        tracker.logger = logger
        return tracker
    }()
    
    lazy var scannedCardsRepository: ScannedCardsRepository = ScannedCardsRepository(storage: persistentStorage)
    lazy var cardsRepository: CardsRepository = {
        let crepo = CardsRepository()
        crepo.tangemSdk = tangemSdk
        crepo.validatedCardsService = keychainService
        crepo.assembly = assembly
        crepo.delegate = self
        crepo.scannedCardsRepository = scannedCardsRepository
        return crepo
    }()
    
    
    lazy var twinsWalletCreationService = {
        TwinsWalletCreationService(tangemSdk: tangemSdk,
                                   twinFileEncoder: TwinCardTlvFileEncoder(),
                                   cardsRepository: cardsRepository,
                                   validatedCardsService: keychainService)
    }()
    
    
    lazy var signer: TransactionSigner = {
        let signer = DefaultSigner(tangemSdk: self.tangemSdk,
                                   initialMessage: Message(header: nil,
                                                           body: "initial_message_sign_header".localized))
        signer.delegate = cardsRepository
        return signer
    }()
    
    lazy var walletConnectCardScanner: WalletConnectCardScanner = {
        let scanner = WalletConnectCardScanner()
        scanner.assembly = assembly
        scanner.tangemSdk = tangemSdk
        scanner.scannedCardsRepository = scannedCardsRepository
        scanner.tokenItemsRepository = tokenItemsRepository
        return scanner
    }()
    
    private let keysManager = try! KeysManager()
    private let configManager = try! FeaturesConfigManager()
    
    private lazy var defaultSdkConfig: Config = {
        var config = Config()
        config.logСonfig = Log.Config.custom(logLevel: Log.Level.allCases, loggers: [logger])
        return config
    }()
}

extension ServicesAssembly: CardsRepositoryDelegate {
    func onDidScan(_ cardInfo: CardInfo) {
        featuresService.setupFeatures(for: cardInfo.card)
        warningsService.setupWarnings(for: cardInfo.card)
        tokenItemsRepository.setCard(cardInfo.card.cardId ?? "")
        
        if !featuresService.linkedTerminal {
            tangemSdk.config.linkedTerminal = false
        }
        
        if cardInfo.card.isTwinCard {
            tangemSdk.config.cardIdDisplayedNumbersCount = 4
        }
    }
    
    func onWillScan() {
        tangemSdk.config = defaultSdkConfig
    }
}

class Assembly: ObservableObject {
    public let services: ServicesAssembly
    private var modelsStorage = [String : Any]()
    
    init() {
        services = ServicesAssembly()
        services.assembly = self
    }
    
    deinit {
        print("Assembly deinit")
    }
    
    func makeReadViewModel() -> ReadViewModel {
        if let restored: ReadViewModel = get() {
            return restored
        }
        
        let vm =  ReadViewModel()
        initialize(vm)
        vm.failedCardScanTracker = services.failedCardScanTracker
        vm.userPrefsService = services.userPrefsService
        vm.cardsRepository = services.cardsRepository
        return vm
    }
    
    // MARK: - Main view model
    func makeMainViewModel() -> MainViewModel {
        if let restored: MainViewModel = get() {
            let restoredCid = restored.state.card?.cardId ?? ""
            let newCid = services.cardsRepository.lastScanResult.card?.cardId ?? ""
            if restoredCid != newCid {
                restored.state = services.cardsRepository.lastScanResult
            }
            return restored
        }
        let vm =  MainViewModel()
        initialize(vm)
        vm.cardsRepository = services.cardsRepository
        vm.imageLoaderService = services.imageLoaderService
        vm.topupService = services.topupService
        vm.userPrefsService = services.userPrefsService
        vm.warningsManager = services.warningsService
        vm.rateAppController = services.rateAppService

        vm.state = services.cardsRepository.lastScanResult
        
        vm.negativeFeedbackDataCollector = services.negativeFeedbackDataCollector
        vm.failedCardScanTracker = services.failedCardScanTracker
        
        return vm
    }
    
    func makeTokenDetailsViewModel( blockchain: Blockchain, amountType: Amount.AmountType = .coin) -> TokenDetailsViewModel {
        if let restored: TokenDetailsViewModel = get() {
            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
                restored.card = cardModel
            }
            return restored
        }
        
        let vm =  TokenDetailsViewModel(blockchain: blockchain, amountType: amountType)
        initialize(vm)
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.card = cardModel
        }
        vm.topupService = services.topupService
        return vm
    }
    
    ///Make wallets for blockchains
    func makeWallets(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletModel] {
        let walletManagers = makeWalletManagers(from: cardInfo, blockchains: blockchains)
        return makeWalletModels(from: cardInfo, walletManagers: walletManagers)
    }
    
    ///Load all possible wallets for card
    func loadWallets(from cardInfo: CardInfo) -> [WalletModel] {
        guard let cid = cardInfo.card.cardId else { return [] }
        
        var walletManagers: [WalletManager] = .init()
        
        //If this card is Twin, return twinWallet
        if cardInfo.card.isTwinCard,
           let savedPairKey = cardInfo.twinCardInfo?.pairPublicKey,
           let publicKey = cardInfo.card.wallets.first?.publicKey,
           let twinWalletManager = services.walletManagerFactory.makeTwinWalletManager(from: cid,
                                                                                       walletPublicKey: publicKey,
                                                                                       pairKey: savedPairKey,
                                                                                       isTestnet: false) {  //TODO: Do we actually need testnet for twins?
            walletManagers.append(twinWalletManager)
        } else {
            //If this card supports multiwallet feature, load all saved tokens from persistent storage
            if cardInfo.card.isMultiWallet && services.tokenItemsRepository.items.count > 0 {
                //Load erc20 tokens if exists
                let erc20Tokens = services.tokenItemsRepository.items.compactMap { $0.token }
                if !erc20Tokens.isEmpty {
                    if let secpWalletPublicKey = cardInfo.card.wallets.first(where: { $0.curve == .some(.secp256k1) })?.publicKey,
                       let ethereumWalletManager = services.walletManagerFactory.makeEthereumWalletManager(from: cid,
                                                                                                           walletPublicKey: secpWalletPublicKey,
                                                                                                           erc20Tokens: erc20Tokens,
                                                                                                           isTestnet: false) { //TODO: Where we can found info about testnet or not?
                        walletManagers.append(ethereumWalletManager)
                    }
                }
                
                //Load blockchains if exists
                let existingBlockchains = walletManagers.map { $0.wallet.blockchain }
                let additionalBlockchains = services.tokenItemsRepository.items
                    .compactMap ({ $0.blockchain }).filter{ !existingBlockchains.contains($0) }
                let additionalWalletManagers = makeWalletManagers(from: cardInfo, blockchains: additionalBlockchains)
                walletManagers.append(contentsOf: additionalWalletManagers)
            }
            
            //Try found default card wallet
            if let nativeWalletManager = makeNativeWalletManager(from: cardInfo), !walletManagers.contains(where: { $0.wallet.blockchain == nativeWalletManager.wallet.blockchain }) {
                walletManagers.append(nativeWalletManager)
            }
        }
        return makeWalletModels(from: cardInfo, walletManagers: walletManagers)
    }
    
    //Make walletModel from walletManager
    private func makeWalletModels(from cardInfo: CardInfo, walletManagers: [WalletManager]) -> [WalletModel] {
        return walletManagers.map { manager -> WalletModel in
            let model = WalletModel(cardInfo: cardInfo, walletManager: manager)
            model.tokenItemsRepository = services.tokenItemsRepository
            model.ratesService = services.ratesService
            return model
        }
    }
        
    /// Try to load native walletmanager from card
    private func makeNativeWalletManager(from cardInfo: CardInfo) -> WalletManager? {
        if let defaultBlockchain = cardInfo.card.defaultBlockchain,
           let cardWalletManager = makeWalletManagers(from: cardInfo, blockchains: [defaultBlockchain]).first {
            
            if let defaultToken = cardInfo.card.defaultToken {
                _ = cardWalletManager.addToken(defaultToken)
            }
            
            return cardWalletManager
            
        }
        
        return nil
    }
    
    ///Try to make WalletManagers for blockchains with suitable wallet
    private func makeWalletManagers(from cardInfo: CardInfo, blockchains: [Blockchain]) -> [WalletManager] {
        guard let cid = cardInfo.card.cardId else { return [] }
        
        var walletManagers = [WalletManager]()
        
        for blockchain in blockchains {
            if let walletPublicKey = cardInfo.card.wallets.first(where: { $0.curve == blockchain.curve })?.publicKey,
               let wm = services.walletManagerFactory.makeWalletManager(from: cid,
                                                                        walletPublicKey: walletPublicKey,
                                                                        blockchain: blockchain) {
                walletManagers.append(wm)
            }
        }
        
        return walletManagers
    }
    
    // MARK: Card model
    func makeCardModel(from info: CardInfo) -> CardViewModel {
        let vm = CardViewModel(cardInfo: info)
        vm.featuresService = services.featuresService
        vm.assembly = self
        vm.tangemSdk = services.tangemSdk
        vm.warningsConfigurator = services.warningsService
        vm.warningsAppendor = services.warningsService
        vm.tokenItemsRepository = services.tokenItemsRepository
        vm.userPrefsService = services.userPrefsService
        //TODO: Payid can work only with concrete wallet, not with the whole card
//        if services.featuresService.isPayIdEnabled, let payIdService = PayIDService.make(from: blockchain) {
//            vm.payIDService = payIdService
//        }
        vm.updateState()
        return vm
    }
    
	func makeDisclaimerViewModel(with state: DisclaimerViewModel.State = .read) -> DisclaimerViewModel {
		// This is needed to prevent updating state of views that already in view hierarchy. Creating new model for each state
		// not so good solution, but this crucial when creating Navigation link without condition closures and Navigation link
		// recreates every redraw process. If you don't want to reinstantiate Navigation link, then functionality of pop to
		// specific View in navigation stack will be lost or push navigation animation will be disabled due to use of
		// StackNavigationViewStyle for NavigationView. Probably this is bug in current Apple realisation of NavigationView
		// and NavigationLinks - all navigation logic tightly coupled with View and redraw process.
		
		let name = String(describing: DisclaimerViewModel.self) + "_\(state)"
        let isTwin = services.cardsRepository.lastScanResult.cardModel?.isTwinCard ?? false
		if let vm: DisclaimerViewModel = get(key: name) {
            vm.isTwinCard = isTwin
			return vm
		}
		
		let vm = DisclaimerViewModel()
        vm.state = state
        vm.isTwinCard = isTwin
        vm.userPrefsService = services.userPrefsService
		initialize(vm, with: name)
        return vm
    }
    
    // MARK: - Details
    
    func makeDetailsViewModel() -> DetailsViewModel {
        
        if let restored: DetailsViewModel = get() {
            if let cardModel = services.cardsRepository.lastScanResult.cardModel {
                restored.cardModel = cardModel
            }
            return restored
        }
        
        let vm =  DetailsViewModel()
        initialize(vm)
        
        if let cardModel = services.cardsRepository.lastScanResult.cardModel {
            vm.cardModel = cardModel
            vm.dataCollector = DetailsFeedbackDataCollector(cardModel: cardModel)
        }
        vm.cardsRepository = services.cardsRepository
        vm.ratesService = services.ratesService
        return vm
    }
    
    func makeSecurityManagementViewModel(with card: CardViewModel) -> SecurityManagementViewModel {
        if let restored: SecurityManagementViewModel = get() {
            return restored
        }
        
        let vm = SecurityManagementViewModel()
        initialize(vm)
        vm.cardViewModel = card
        return vm
    }
    
    func makeCurrencySelectViewModel() -> CurrencySelectViewModel {
        if let restored: CurrencySelectViewModel = get() {
            return restored
        }
        
        let vm =  CurrencySelectViewModel()
        initialize(vm)
        vm.ratesService = services.ratesService
        return vm
    }
    
//    func makeManageTokensViewModel(with walletModels: [WalletModel]) -> ManageTokensViewModel {
//        if let restored: ManageTokensViewModel = get() {
//            return restored
//        }
//
//        let vm = ManageTokensViewModel(walletModels: walletModels)
//        initialize(vm)
//        return vm
//    }
    
    func makeAddTokensViewModel(for cardModel: CardViewModel) -> AddNewTokensViewModel {
        if let restored: AddNewTokensViewModel = get() {
            return restored
        }
        
        let vm = AddNewTokensViewModel(cardModel: cardModel)
        initialize(vm)
        vm.tokenItemsRepository = services.tokenItemsRepository
        return vm
    }
    
//    func makeAddCustomTokenViewModel(for wallet: WalletModel) -> AddCustomTokenViewModel {
//        if let restored: AddCustomTokenViewModel = get() {
//            return restored
//        }
//        let vm = AddCustomTokenViewModel(walletModel: wallet)
//        initialize(vm)
//        return vm
//    }
    
    func makeSendViewModel(with amount: Amount, blockchain: Blockchain, card: CardViewModel) -> SendViewModel {
        if let restored: SendViewModel = get() {
            return restored
        }
        
        let vm = SendViewModel(amountToSend: amount,
                               blockchain: blockchain,
                               cardViewModel: card,
                               signer: services.signer,
                               warningsManager: services.warningsService)
        initialize(vm)
        vm.ratesService = services.ratesService
        vm.featuresService = services.featuresService
        vm.emailDataCollector = SendScreenDataCollector(sendViewModel: vm)
        return vm
    }
	
    func makeTwinCardOnboardingViewModel(isFromMain: Bool) -> TwinCardOnboardingViewModel {
        let scanResult = services.cardsRepository.lastScanResult
        let twinInfo = scanResult.cardModel?.cardInfo.twinCardInfo
        let twinPairCid = TapTwinCardIdFormatter.format(cid: twinInfo?.pairCid ?? "", cardNumber: twinInfo?.series?.pair.number ?? 1)
		return makeTwinCardOnboardingViewModel(state: .onboarding(withPairCid: twinPairCid, isFromMain: isFromMain))
	}
	
    func makeTwinCardWarningViewModel(isRecreating: Bool) -> TwinCardOnboardingViewModel {
        makeTwinCardOnboardingViewModel(state: .warning(isRecreating: isRecreating))
	}
	
	func makeTwinCardOnboardingViewModel(state: TwinCardOnboardingViewModel.State) -> TwinCardOnboardingViewModel {
		let key = String(describing: TwinCardOnboardingViewModel.self) + "_" + state.storageKey
		if let vm: TwinCardOnboardingViewModel = get(key: key) {
            vm.state = state
			return vm
		}
		
        let vm = TwinCardOnboardingViewModel(state: state, imageLoader: services.imageLoaderService)
		initialize(vm, with: key)
        vm.userPrefsService = services.userPrefsService
		return vm
	}
	
	func makeTwinsWalletCreationViewModel(isRecreating: Bool) -> TwinsWalletCreationViewModel {
        if let twinInfo = services.cardsRepository.lastScanResult.cardModel!.cardInfo.twinCardInfo {
            services.twinsWalletCreationService.setupTwins(for: twinInfo)
        }
		if let vm: TwinsWalletCreationViewModel = get() {
            vm.walletCreationService = services.twinsWalletCreationService
			return vm
		}
		
		let vm = TwinsWalletCreationViewModel(isRecreatingWallet: isRecreating,
                                              walletCreationService: services.twinsWalletCreationService,
                                              imageLoaderService: services.imageLoaderService)
		initialize(vm)
		return vm
	}
    
    func makeWalletConnectViewModel(cardModel: CardViewModel) -> WalletConnectViewModel {
        let vm = WalletConnectViewModel(cardModel: cardModel)
        initialize(vm)
        vm.walletConnectController = services.walletConnectService
        return vm
    }

    public func reset() {
        var persistentKeys = [String]()
        persistentKeys.append(String(describing: type(of: MainViewModel.self)))
        persistentKeys.append(String(describing: type(of: ReadViewModel.self)))
        persistentKeys.append(String(describing: DisclaimerViewModel.self) + "_\(DisclaimerViewModel.State.accept)")
        persistentKeys.append(String(describing: TwinCardOnboardingViewModel.self) + "_" + TwinCardOnboardingViewModel.State.onboarding(withPairCid: "", isFromMain: false).storageKey)
        
        let indicesToRemove = modelsStorage.keys.filter { !persistentKeys.contains($0) }
        indicesToRemove.forEach { modelsStorage.removeValue(forKey: $0) }
    }
    
    public func reset(key: String) {
        modelsStorage.removeValue(forKey: key)
    }
    
    // MARK: - Private funcs
    
    private func initialize<V: ViewModel>(_ vm: V) {
        vm.navigation = services.navigationCoordinator
        vm.assembly = self
        store(vm)
    }
	
	private func initialize<V: ViewModel>(_ vm: V, with key: String) {
        vm.navigation = services.navigationCoordinator
		vm.assembly = self
		store(vm, with: key)
	}
	
    private func store<T>(_ object: T ) {
        let key = String(describing: type(of: T.self))
        store(object, with: key)
    }
	
	private func store<T>(_ object: T, with key: String) {
		//print(key)
		modelsStorage[key] = object
	}
    
    private func get<T>() -> T? {
        let key = String(describing: type(of: T.self))
        return get(key: key)
    }
	
	private func get<T>(key: String) -> T? {
		modelsStorage[key] as? T
	}
}

extension Assembly {
    enum PreviewCard {
        case withoutWallet, twin, ethereum, stellar, v4
        
        static func scanResult(for preview: PreviewCard, assembly: Assembly) -> ScanResult {
            let card = preview.card
            let ci = CardInfo(card: card,
                              artworkInfo: nil,
                              twinCardInfo: preview.twinInfo)
            let vm = assembly.makeCardModel(from: ci)
            let scanResult = ScanResult.card(model: vm)
            assembly.services.cardsRepository.cards[card.cardId!] = scanResult
            return scanResult
        }
        
        var card: Card {
            switch self {
            case .withoutWallet: return .testCardNoWallet
            case .twin: return .testTwinCard
            case .ethereum: return .testEthCard
            case .stellar: return .testXlmCard
            case .v4: return .v4Card
            }
        }
        
        private var twinInfo: TwinCardInfo? {
            switch self {
            case .twin: return TwinCardInfo(cid: "CB64000000006522", series: .cb64, pairCid: "CB65000000006521", pairPublicKey: nil)
            default: return nil
            }
        }
    }
    
    static func previewAssembly(for card: PreviewCard) -> Assembly {
        let assembly = Assembly()
        
        assembly.services.cardsRepository.lastScanResult = PreviewCard.scanResult(for: card, assembly: assembly)
        return assembly
    }
    
    static func previewCardViewModel(for card: PreviewCard) -> CardViewModel {
        previewAssembly(for: card).services.cardsRepository.cards[card.card.cardId!]!.cardModel!
    }
    
    static var previewAssembly: Assembly {
        .previewAssembly(for: .v4)
    }
    
    var previewCardViewModel: CardViewModel {
        services.cardsRepository.lastScanResult.cardModel!
    }
    
    var previewBlockchain: Blockchain {
        previewCardViewModel.wallets!.first!.blockchain
    }
}
