//
//  AppDelegate.swift
//  HueHelper
//
//  Created by Rogers, April on 5/31/16.
//  Copyright © 2016 April Rogers. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, BridgePushLinkViewControllerDelegate {

    // Create sdk instance
    let phHueSdk: PHHueSDK = PHHueSDK()
    var window: UIWindow?
    var navigationController: UINavigationController?
    var noConnectionAlert: UIAlertController?
    var noBridgeFoundAlert: UIAlertController?
    var authenticationFailedAlert: UIAlertController?
    var loadingView: LoadingViewController?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        phHueSdk.startUpSDK()
        phHueSdk.enableLogging(true)
        let notificationManager = PHNotificationManager.defaultManager()
        
        navigationController = window!.rootViewController as? UINavigationController

        notificationManager.registerObject(self, withSelector:#selector(localConnection) , forNotification: LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector:#selector(noLocalConnection), forNotification: NO_LOCAL_CONNECTION_NOTIFICATION)
        notificationManager.registerObject(self, withSelector:#selector(notAuthenticated), forNotification: NO_LOCAL_AUTHENTICATION_NOTIFICATION)
        
        enableLocalHeartbeat()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        disableLocalHeartbeat()
        
        // Remove any open popups
        noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
        noConnectionAlert = nil
        noBridgeFoundAlert?.dismissViewControllerAnimated(false, completion: nil)
        noBridgeFoundAlert = nil
        authenticationFailedAlert?.dismissViewControllerAnimated(false, completion: nil)
        authenticationFailedAlert = nil
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: - HueSDK
    func localConnection() {
        checkConnectionState()
    }
    
    func noLocalConnection() {
        checkConnectionState()
    }
    
    func notAuthenticated() {
        navigationController!.popToRootViewControllerAnimated(false)
        
        if navigationController!.presentedViewController != nil {
            navigationController!.dismissViewControllerAnimated(true, completion: nil)
        }
        
        noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
        noConnectionAlert = nil
        
        let delay = 0.5 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.doAuthentication()
        }
    }
    
    func checkConnectionState() {
        if !phHueSdk.localConnected() {
            
            if navigationController!.presentedViewController != nil {
                navigationController!.dismissViewControllerAnimated(true, completion: nil)
            }
            
            if noConnectionAlert == nil {
                navigationController!.popToRootViewControllerAnimated(true)
                
                removeLoadingView()
                showNoConnectionDialog()
            }
        } else {
            noConnectionAlert?.dismissViewControllerAnimated(false, completion: nil)
            noConnectionAlert = nil
            removeLoadingView()
        }
    }

    func showNoConnectionDialog() {
        noConnectionAlert = UIAlertController(
            title: NSLocalizedString("No Connection", comment: "No connection alert title"),
            message: NSLocalizedString("Connection to bridge is lost", comment: "No Connection alert message"),
            preferredStyle: .Alert
        )
        
        let reconnectAction = UIAlertAction(
            title: NSLocalizedString("Reconnect", comment: "No connection alert reconnect button"),
            style: .Default
        ) { (_) in
            self.showLoadingViewWithText(NSLocalizedString("Connecting...", comment: "Connecting text"))
        }
        noConnectionAlert!.addAction(reconnectAction)
        
        let newBridgeAction = UIAlertAction(
            title: NSLocalizedString("Find new bridge", comment: "No connection find new bridge button"),
            style: .Default
        ) { (_) in
            self.searchForBridgeLocal()
        }
        noConnectionAlert!.addAction(newBridgeAction)
        
        let cancelAction = UIAlertAction(
            title: NSLocalizedString("Cancel", comment: "No bridge found alert cancel button"),
            style: .Cancel
        ) { (_) in
            self.disableLocalHeartbeat()
        }
        noConnectionAlert!.addAction(cancelAction)
        window!.rootViewController!.presentViewController(noConnectionAlert!, animated: true, completion: nil)
    }
    
    // MARK: - Heartbeat control
    /// Starts the local heartbeat with a 10 second interval
    func enableLocalHeartbeat() {
        // The heartbeat processing collects data from the bridge so now try to see if we have a bridge already connected
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        if cache?.bridgeConfiguration?.ipaddress != nil {
            showLoadingViewWithText(NSLocalizedString("Connecting", comment: "Connecting text"))
            phHueSdk.enableLocalConnection()
        } else {
            searchForBridgeLocal()
        }
    }

    func disableLocalHeartbeat() {
        phHueSdk.disableLocalConnection()
    }
    
    // MARK: - Bridge searching
    func searchForBridgeLocal() {
        disableLocalHeartbeat()
        
        showLoadingViewWithText(NSLocalizedString("Searching", comment: "Searching for bridges text"))
        let bridgeSearch = PHBridgeSearching(upnpSearch: true, andPortalSearch: true, andIpAdressSearch: true)
        bridgeSearch.startSearchWithCompletionHandler { (bridgesFound: [NSObject: AnyObject]!) -> () in
            self.removeLoadingView()
            
            if bridgesFound.count > 0 {
                let bridges = bridgesFound as! [String: String]
                let keys = [String](bridges.keys)
                let id = keys[0]
                let ip = bridges[id]!
                
                self.bridgeSelectedWithIpAddress(ip, andBridgeId:id)
            }
            else {
                self.noBridgeFoundAlert = UIAlertController(
                    title: NSLocalizedString("No bridges", comment: "No bridge found alert title"),
                    message: NSLocalizedString("Could not find bridge", comment: "No bridge found alert message"),
                    preferredStyle: .Alert
                )
                
                let retryAction = UIAlertAction(
                    title: NSLocalizedString("Rertry", comment: "No bridge found alert retry button"),
                    style: .Default
                ) { (_) in
                    self.searchForBridgeLocal()
                }
                self.noBridgeFoundAlert!.addAction(retryAction)
                let cancelAction = UIAlertAction(
                    title: NSLocalizedString("Cancel", comment: "No bridge found alert cancel button"),
                    style: .Cancel
                ) { (_) in
                    self.disableLocalHeartbeat()
                }
                self.noBridgeFoundAlert!.addAction(cancelAction)
                self.window!.rootViewController!.presentViewController(self.noBridgeFoundAlert!, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Bridge authentication
    func doAuthentication() {
        disableLocalHeartbeat()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let pushLinkViewController = storyboard.instantiateViewControllerWithIdentifier("BridgePushLink") as! BridgePushLinkViewController
        
        pushLinkViewController.modalPresentationStyle = UIModalPresentationStyle.FormSheet
        pushLinkViewController.phHueSdk = phHueSdk
        pushLinkViewController.delegate = self
        navigationController?.presentViewController(
            pushLinkViewController,
            animated: true,
            completion: {(bool) in
                pushLinkViewController.startPushLinking()
        })
    }
    
    // MARK: - Loading view
    func showLoadingViewWithText(text:String) {
        removeLoadingView()
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        loadingView = storyboard.instantiateViewControllerWithIdentifier("Loading") as? LoadingViewController
        loadingView!.view.frame = navigationController!.view.bounds
        navigationController?.view.addSubview(loadingView!.view)
        loadingView!.loadingLabel?.text = text
    }
    
    func removeLoadingView() {
        loadingView?.view.removeFromSuperview()
        loadingView = nil
    }
    
    func bridgeSelectedWithIpAddress(ipAddress:String, andBridgeId bridgeId:String) {
        showLoadingViewWithText(NSLocalizedString("Connecting", comment: "Connecting text"))
        phHueSdk.setBridgeToUseWithId(bridgeId, ipAddress: ipAddress)
        
        // Setting the hearbeat running will cause the SDK to regularly update the cache with the status of the bridge resources
        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.enableLocalHeartbeat()
        }
    }
    
    //MARK: - Push Linking
    func pushlinkSuccess() {
        navigationController!.dismissViewControllerAnimated(true, completion: nil)

        let delay = 1 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            self.enableLocalHeartbeat()
        }
    }

    func pushlinkFailed(error: PHError) {
        navigationController!.dismissViewControllerAnimated(true, completion: nil)
        
        if error.code == Int(PUSHLINK_NO_CONNECTION.rawValue) {
            noLocalConnection()
                        let delay = 1 * Double(NSEC_PER_SEC)
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
            dispatch_after(time, dispatch_get_main_queue()) {
                self.enableLocalHeartbeat()
            }
        } else {
            authenticationFailedAlert = UIAlertController(
                title: NSLocalizedString("Authentication failed", comment: "Authentication failed alert title"),
                message: NSLocalizedString("Make sure you press the button within 30 seconds", comment: "Authentication failed alert message"),
                preferredStyle: .Alert
            )
            
            let retryAction = UIAlertAction(
                title: NSLocalizedString("Retry", comment: "Authentication failed alert retry button"),
                style: .Default
            ) { (_) in
                self.doAuthentication()
            }
            authenticationFailedAlert!.addAction(retryAction)
            
            let cancelAction = UIAlertAction(
                title: NSLocalizedString("Cancel", comment: "Authentication failed cancel button"),
                style: .Cancel
            ) { (_) in
                self.removeLoadingView()
                self.disableLocalHeartbeat()
            }
            authenticationFailedAlert!.addAction(cancelAction)
            
            window!.rootViewController!.presentViewController(authenticationFailedAlert!, animated: true, completion: nil)
        }
    }
}

