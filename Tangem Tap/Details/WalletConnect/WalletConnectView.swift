//
//  WalletConnectView.swift
//  Tangem Tap
//
//  Created by Alexander Osokin on 22.03.2021.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI
import AVFoundation

struct WalletConnectView: View {
    @ObservedObject var viewModel: WalletConnectViewModel
    @EnvironmentObject var navigation: NavigationCoordinator
    
    @State private var isActionSheetVisible: Bool = false
    @State private var showCameraDeniedAlert: Bool = false
    
    @ViewBuilder
    var navBarButton: some View {
        NavigationBusyButton(isBusy: viewModel.isServiceBusy, color: .tangemTapBlue, systemImageName: "plus", action: {
            if viewModel.hasWCInPasteboard {
                isActionSheetVisible = true
            } else {
                scanQrCode()
            }
        }).accessibility(label: Text("voice_over_open_new_wallet_connect_session"))
        .sheet(isPresented: $navigation.walletConnectToQR) {
            QRScanView(code: $viewModel.code)
                .edgesIgnoringSafeArea(.all)
        }
        .cameraAccessDeniedAlert($showCameraDeniedAlert)
    }
    
    var body: some View {
        VStack {
            Color.clear
                .frame(width: 0.5, height: 0.5)
                .actionSheet(isPresented: $isActionSheetVisible, content: {
                    ActionSheet(title: Text("common_select_action"), message: Text("wallet_connect_clipboard_alert"), buttons: [
                        .default(Text("wallet_connect_paste_from_clipboard"), action: {
                            viewModel.pasteFromClipboard()
                        }),
                        .default(Text("wallet_connect_scan_new_code"), action: {
                            scanQrCode()
                        }),
                        .cancel()
                    ])
                })
            if viewModel.sessions.count == 0 {
                Text("wallet_connect_no_sessions_title")
                    .font(.system(size: 24, weight: .semibold))
                    .padding(.bottom, 10)
                Text("wallet_connect_no_sessions_message")
                    .multilineTextAlignment(.center)
                    .font(.system(size: 17, weight: .medium))
                    .padding(.horizontal, 40)
            } else {
                List {
                    ForEach(Array(viewModel.sessions.enumerated()), id: \.element) { (i, item) -> WalletConnectSessionItemView in
                        WalletConnectSessionItemView(dAppName: item.session.dAppInfo.peerMeta.name,
                                                            cardId: item.wallet.cid) {
                            viewModel.disconnectSession(at: i)
                        }
                    }
                    .listRowInsets(.none)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.tangemTapBgGray.edgesIgnoringSafeArea(.all))
        .navigationBarTitle(Text("wallet_connect_sessions_title"))
        .navigationBarItems(trailing: navBarButton)
        .alert(item: $viewModel.alert) { $0.alert }
    }
    
    private func scanQrCode() {
        if case .denied = AVCaptureDevice.authorizationStatus(for: .video) {
            showCameraDeniedAlert = true
        } else {
            viewModel.scanQrCode()
        }
    }
}

struct WalletConnectView_Previews: PreviewProvider {
    static let assembly = Assembly.previewAssembly
    
    static var previews: some View {
        WalletConnectView(viewModel: assembly.makeWalletConnectViewModel(cardModel: assembly.services.cardsRepository.lastScanResult.cardModel!))
            .environmentObject(NavigationCoordinator())
            .previewGroup(devices: [.iPhone12Pro])
    }
}
