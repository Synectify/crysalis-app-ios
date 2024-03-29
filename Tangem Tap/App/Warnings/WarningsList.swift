//
//  WarningsList.swift
//  Tangem Tap
//
//  Created by Andrew Son on 30/12/20.
//  Copyright © 2020 Tangem AG. All rights reserved.
//

import Foundation

struct WarningsList {
    static let warningTitle = "common_warning".localized
    
    static let oldCard = TapWarning(title: warningTitle, message: "alert_old_card".localized, priority: .info, type: .permanent)
    static let oldDeviceOldCard = TapWarning(title: warningTitle, message: "alert_old_device_this_card".localized, priority: .info, type: .permanent)
    static let devCard = TapWarning(title: warningTitle, message: "alert_developer_card".localized, priority: .critical, type: .permanent)
    static let numberOfSignedHashesIncorrect = TapWarning(title: warningTitle, message: "alert_card_signed_transactions".localized, priority: .info, type: .temporary, event: .numberOfSignedHashesIncorrect)
    static let rateApp = TapWarning(title: "warning_rate_app_title".localized, message: "warning_rate_app_message".localized, priority: .info, type: .temporary, event: .rateApp)
    static let failedToVerifyCard = TapWarning(title: "warning_failed_to_verify_card_title".localized, message: "warning_failed_to_verify_card_message".localized, priority: .critical, type: .permanent, event: .failedToValidateCard)
    static let multiWalletSignedHashes = TapWarning(title: "warning_important_security_info".localized, message: "warning_signed_tx_previously".localized, priority: .info, type: .temporary, location: [.main], event: .multiWalletSignedHashes)
    
    static func lowSignatures(count: Int) -> TapWarning {
        let message = String(format: "warning_low_signatures_format".localized, "\(count)")
        return TapWarning(title: warningTitle, message: message, priority: .critical, type: .permanent)
    }
}
