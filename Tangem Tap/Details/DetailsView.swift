//
//  DetailsView.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 31.08.2020.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI
import TangemSdk

struct DetailsRowView: View {
    var title: String
    var subtitle: String
    var body: some View {
        HStack (alignment: .center) {
            Text(title)
                .font(Font.system(size: 16.0, weight: .regular, design: .default))
                .foregroundColor(.tangemTapGrayDark6)
            Spacer()
            Text(subtitle)
                .font(Font.system(size: 16.0, weight: .regular, design: .default))
                .foregroundColor(.tangemTapGrayDark)
        }
       // .padding(.leading)
        //.listRowInsets(EdgeInsets())
    }
}

struct DetailsView: View {
    private enum NavigationTag: String {
        case currency, disclaimer, cardTermsOfUse, securityManagement, cardOperation, manageTokens, walletConnect
    }
    
    @ObservedObject var viewModel: DetailsViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    //fix remain highlited bug on ios14
    @State private var selection: NavigationTag? = nil
    
    var body: some View {
        List {
            Section(header: HeaderView(text: "details_section_title_card".localized), footer: footerView) {
                DetailsRowView(title: "details_row_title_cid".localized,
                               subtitle: viewModel.cardCid)
                DetailsRowView(title: "details_row_title_issuer".localized,
                               subtitle: viewModel.cardModel.cardInfo.card.cardData?.issuerName ?? " ")

                if viewModel.hasWallet, !viewModel.isTwinCard {
                    DetailsRowView(title: "details_row_title_signed_hashes".localized,
                                   subtitle: String(format: "details_row_subtitle_signed_hashes_format".localized,
                                                    viewModel.cardModel.cardInfo.card.walletSignedHashes.description))
                }
                Button(action: {
                    viewModel.checkPin {
                        selection = .securityManagement
                    }
                }, label: {
                    Text("details_row_title_manage_security")
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.tangemTapGrayDark6)
                })
                .background(
                    NavigationLink(
                        destination: SecurityManagementView(viewModel: viewModel.assembly.makeSecurityManagementViewModel(with: viewModel.cardModel)),
                        tag: NavigationTag.securityManagement,
                        selection: $selection,
                        label: { EmptyView() })
                        .disabled(true)
                )
                
                if viewModel.isTwinCard {
                    NavigationLink(destination: TwinCardOnboardingView(viewModel: viewModel.assembly.makeTwinCardWarningViewModel(isRecreating: true)),
                                   isActive: $navigation.detailsToTwinsRecreateWarning){
                        DetailsRowView(title: "details_row_title_twins_recreate".localized, subtitle: "")
                    }
                    .disabled(!viewModel.cardModel.canRecreateTwinCard)
                    
                } else {
                    NavigationLink(destination: CardOperationView(title: "details_row_title_erase_wallet".localized,
                                                                  buttonTitle: "details_row_title_erase_wallet",
                                                                  alert: "details_erase_wallet_warning".localized,
                                                                  actionButtonPressed: {self.viewModel.cardModel.purgeWallet(completion: $0)}
                    ),
                    tag: NavigationTag.cardOperation, selection: $selection) {
                        DetailsRowView(title: "details_row_title_erase_wallet".localized, subtitle: "")
                    }
                    .disabled(!viewModel.cardModel.canPurgeWallet)
                }
            }
            
            Section(header: HeaderView(text: "details_section_title_app".localized), footer: FooterView()) {
                NavigationLink(destination: CurrencySelectView(viewModel: viewModel.assembly.makeCurrencySelectViewModel()),
                               tag: NavigationTag.currency, selection: $selection) {
                    DetailsRowView(title: "details_row_title_currency".localized,
                                   subtitle: viewModel.ratesService.selectedCurrencyCode)
                    
                }
                
                NavigationLink(destination: DisclaimerView(viewModel: viewModel.assembly.makeDisclaimerViewModel(with: .read))
                                .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all)),
                               tag: NavigationTag.disclaimer, selection: $selection) {
                    DetailsRowView(title: "disclaimer_title".localized,
                                   subtitle: "")
                    
                }
                Button(action: {
                    navigation.detailsToSendEmail = true
                }, label: {
                    Text("details_row_title_send_feedback".localized)
                        .font(.system(size: 16, weight: .regular, design: .default))
                        .foregroundColor(.tangemTapGrayDark6)
                })
                .sheet(isPresented: $navigation.detailsToSendEmail, content: {
                    MailView(dataCollector: viewModel.dataCollector, support: viewModel.cardModel.emailSupport, emailType: EmailType.appFeedback)
                })
                
                if let cardTouURL = viewModel.cardTouURL {
                    NavigationLink(destination: WebViewContainer(url: cardTouURL, title: "details_row_title_card_tou")
                                    .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all)),
                                   tag: NavigationTag.cardTermsOfUse, selection: $selection) {
                        DetailsRowView(title: "details_row_title_card_tou".localized,
                                       subtitle: "")
                        
                    }
                }
                
                NavigationLink(destination: WalletConnectView(viewModel: viewModel.assembly.makeWalletConnectViewModel(cardModel: viewModel.cardModel))
                                .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all)),
                               tag: NavigationTag.walletConnect, selection: $selection) {
                    DetailsRowView(title: "WalletConnect",
                                   subtitle: "")
                    
                }
            }
            Section(header: Color.tangemTapBgGray
                        .listRowInsets(EdgeInsets())) {
                EmptyView()
            }
        }
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle("details_title", displayMode: .inline)
        .navigationBarBackButtonHidden(false)
        .navigationBarHidden(false)
        .onDisappear {
            if #available(iOS 14.5, *) { } else {
                if #available(iOS 14.3, *) {
                    // remains selection fix from 14.3 to 14.5
                    self.selection = nil
                }
            }
        }
    }
    
    var footerView: some View {
        if let purgeWalletProhibitedDescription = viewModel.cardModel.purgeWalletProhibitedDescription {
            return FooterView(text: purgeWalletProhibitedDescription)
        }
        
        return FooterView()
    }
}

extension DetailsView {
    struct HeaderView: View {
        var text: String
        var additionalTopPadding: CGFloat = 0
        var body: some View {
            HStack {
                Text(text)
                    .font(.headline)
                    .foregroundColor(.tangemTapBlue)
                    .padding(16)
                Spacer()
            }
            .padding(.top, additionalTopPadding)
            .background(Color.tangemTapBgGray)
            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 1, trailing: 0))
        }
    }
    
    struct FooterView: View {
        var text: String = ""
        var additionalBottomPadding: CGFloat = 0
        var body: some View {
            if text.isEmpty {
                Color.tangemTapBgGray
                    .listRowBackground(Color.tangemTapBgGray)
                    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(height: 0)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    Text(text)
                        .font(.footnote)
                        .foregroundColor(.tangemTapGrayDark)
                        .padding()
                        .padding(.bottom, additionalBottomPadding)
                    Color.clear.frame(height: 0)
                }
                .background(Color.tangemTapBgGray)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly(for: .ethereum)
    
    static var previews: some View {
        NavigationView {
            DetailsView(viewModel: assembly.makeDetailsViewModel())
                .environmentObject(assembly.services.navigationCoordinator)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

