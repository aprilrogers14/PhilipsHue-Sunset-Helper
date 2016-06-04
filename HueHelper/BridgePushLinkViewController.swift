//
//  BridgePushLinkViewController.swift
//  HueHelper
//
//  Created by Rogers, April on 5/31/16.
//  Copyright © 2016 April Rogers. All rights reserved.
//


import UIKit

protocol BridgePushLinkViewControllerDelegate {
  func pushlinkSuccess()
  func pushlinkFailed(error: PHError)
}

class BridgePushLinkViewController: UIViewController {
  
    @IBOutlet var progressView: UIProgressView!
    var phHueSdk: PHHueSDK!
    var delegate: BridgePushLinkViewControllerDelegate!
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
  
    func startPushLinking() {
        let notificationManager = PHNotificationManager.defaultManager()

        notificationManager.registerObject(self, withSelector: #selector(BridgePushLinkViewController.authenticationSuccess), forNotification: PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION)

        notificationManager.registerObject(self, withSelector: #selector(BridgePushLinkViewController.authenticationFailed), forNotification: PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION)

        notificationManager.registerObject(self, withSelector: #selector(BridgePushLinkViewController.noLocalConnection), forNotification: PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION)

        notificationManager.registerObject(self, withSelector: #selector(BridgePushLinkViewController.noLocalBridge), forNotification: PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION)

        notificationManager.registerObject(self, withSelector: #selector(BridgePushLinkViewController.buttonNotPressed(_:)), forNotification: PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION)

        phHueSdk.startPushlinkAuthentication()
    }

    func authenticationSuccess() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
        delegate.pushlinkSuccess()
    }
  
    func authenticationFailed() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
        let error = PHError(domain: SDK_ERROR_DOMAIN, code: Int(PUSHLINK_TIME_LIMIT_REACHED.rawValue), userInfo: [NSLocalizedDescriptionKey: "Authentication failed: time limit reached."])

        delegate.pushlinkFailed(error)
    }
  
    func noLocalConnection() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
        let error = PHError(domain: SDK_ERROR_DOMAIN, code: Int(PUSHLINK_NO_CONNECTION.rawValue), userInfo: [NSLocalizedDescriptionKey: "Authentication failed: No local connection to bridge."])

        delegate.pushlinkFailed(error)
    }
  
    func noLocalBridge() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
        let error = PHError(domain: SDK_ERROR_DOMAIN, code: Int(PUSHLINK_NO_LOCAL_BRIDGE.rawValue), userInfo: [NSLocalizedDescriptionKey: "Authentication failed: No local bridge found."])

        delegate.pushlinkFailed(error)
    }
  
    /// This method is called when the pushlinking is still ongoing but no button was pressed yet.
    /// - parameter notification: The notification which contains the pushlinking percentage which has passed.
    func buttonNotPressed(notification: NSNotification) {
        let dict = notification.userInfo!
        let progressPercentage = dict["progressPercentage"] as! Int!

        let progressBarValue = Float(progressPercentage) / 100.0
        progressView.progress = progressBarValue
    }
}
