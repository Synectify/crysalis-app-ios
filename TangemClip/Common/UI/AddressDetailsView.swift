//
//  AddressDetailsView.swift
//  TangemClip
//
//  Created by Andrew Son on 24/03/21.
//  Copyright © 2021 Tangem AG. All rights reserved.
//

import SwiftUI

struct AddressDetailView: View {
    @Binding var selectedAddressIndex: Int
    var walletModel: WalletModel
    
    var showAddressSelector: Bool {
        return walletModel.wallet.addresses.count > 1
    }
    
    var pickerViews: [Text] {
        var views = [Text]()
        for (index, address) in walletModel.wallet.addresses.enumerated() {
            let textView = Text(address.localizedName).tag(index) as! Text
            views.append(textView)
        }
        
        return views
    }
    
    var body: some View {
        VStack(spacing: 0.0) {
            if showAddressSelector {
                PickerView(contents: walletModel.addressNames, selection: $selectedAddressIndex)
                .padding(.horizontal, 24)
                .padding(.top, 8)
            }
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(walletModel.displayAddress(for: selectedAddressIndex))
                        .font(Font.system(size: 14.0, weight: .medium, design: .default))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundColor(Color.tangemTapGrayDark)
                    Button(action: {
                        if let url = walletModel.exploreURL(for: selectedAddressIndex) {
                            UIApplication.shared.open(url, options: [:], completionHandler: nil)
                        }
                    }) {
                        HStack {
                            Text("wallet_address_button_explore")
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                                .multilineTextAlignment(.leading)
                                .lineLimit(1)
                            Image ("chevron.right")
                                .font(Font.system(size: 14.0, weight: .bold, design: .default))
                                .foregroundColor(Color.tangemTapGrayDark6)
                        }
                    }
                }
                Spacer()
                CircleActionButton(action: {  UIPasteboard.general.string = walletModel.displayAddress(for: selectedAddressIndex) },
                                   backgroundColor: .tangemTapBgGray,
                                   imageName: "square.on.square",
                                   isSystemImage: false,
                                   imageColor: .tangemTapGrayDark6,
                                   withVerification: true,
                                   isDisabled: false)
                
//                CircleActionButton(action: { self.showQr = true },
//                                   backgroundColor: .tangemTapBgGray,
//                                   imageName: "qrcode",
//                                   isSystemImage: false,
//                                   imageColor: .tangemTapGrayDark6,
//                                   isDisabled: false)
            }
            .padding(.horizontal, 24.0)
            .padding(.vertical, 16.0)
        }
        .background(Color.white)
        .cornerRadius(6.0)
        .padding(.horizontal, 16.0)
    }
}

struct AddressDetailView_Previews: PreviewProvider {
    @State static var cardViewModel = CardViewModel.previewCardViewModel
    @State static var showPayID = false
    @State static var showQR = false
    @State static var addressIndex = 0
    
    static var previews: some View {
        ZStack {
            Color.tangemTapBgGray
            AddressDetailView(selectedAddressIndex: $addressIndex,
                              walletModel: cardViewModel.walletModels.first!)
        }.previewGroup()
    }
}
