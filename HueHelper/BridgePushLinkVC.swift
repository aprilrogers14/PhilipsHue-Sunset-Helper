//
//  BridgePushLinkVC.swift
//  HueHelper
//
//  Created by Rogers, April on 5/31/16.
//  Copyright © 2016 April Rogers. All rights reserved.
//

import UIKit

protocol BridgePuchLinkViewControllerDelegate {
    func pushlinkSuccess()
}

class BridgePushLink: UIViewController {
    
    var hueDelegate: BridgePuchLinkViewControllerDelegate?
    var phHueSDK: PHHueSDK?
    
    convenience init(hueSKD: PHHueSDK, delegate: BridgePuchLinkViewControllerDelegate) {
        self.init()
        
        hueDelegate = delegate
        phHueSDK = hueSKD
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startPushLinking() {
        let phNotificationMgr = PHNotificationManager.defaultManager();
        
        phNotificationMgr.registerObject(self, withSelector:#selector(authenticationSuccess), forNotification:PUSHLINK_LOCAL_AUTHENTICATION_SUCCESS_NOTIFICATION)
        phNotificationMgr.registerObject(self, withSelector:#selector(authenticationFailed), forNotification:PUSHLINK_LOCAL_AUTHENTICATION_FAILED_NOTIFICATION)
        phNotificationMgr.registerObject(self, withSelector:#selector(noLocalConnection), forNotification:PUSHLINK_NO_LOCAL_CONNECTION_NOTIFICATION)
        phNotificationMgr.registerObject(self, withSelector:#selector(noLocalBridge), forNotification:PUSHLINK_NO_LOCAL_BRIDGE_KNOWN_NOTIFICATION)
        phNotificationMgr.registerObject(self, withSelector:#selector(buttonNotPressed), forNotification:PUSHLINK_BUTTON_NOT_PRESSED_NOTIFICATION)
        
        phHueSDK!.startPushlinkAuthentication();
    }
    
    func authenticationSuccess() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
        
        hueDelegate!.pushlinkSuccess()
    }
    
    func authenticationFailed() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    }
    
    func noLocalConnection() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    }
    
    func noLocalBridge() {
        PHNotificationManager.defaultManager().deregisterObjectForAllNotifications(self)
    }
    
    func buttonNotPressed(notification: NSNotification) {
    
    }
}