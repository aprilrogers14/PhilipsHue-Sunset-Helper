//
//  ViewController.swift
//  HueHelper
//
//  Created by Rogers, April on 5/31/16.
//  Copyright © 2016 April Rogers. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func turnOnAllLights(sender: AnyObject) {
        self.changeAllLightsToState(true)
    }
    
    @IBAction func turnOffAllLights(sender: AnyObject) {
        self.changeAllLightsToState(false)
    }
    
    func changeAllLightsToState(state: Bool) {
        let cache = PHBridgeResourcesReader.readBridgeResourcesCache()
        let bridgeSendAPI = PHBridgeSendAPI()
        
        for light in cache!.lights!.values {
            if light.lightState!.reachable == 0 {
                continue
            }
            
            if let lightState = light.lightState {
                lightState.setOnBool(state)
                
                // Send lightstate to light
                bridgeSendAPI.updateLightStateForId(light.identifier, withLightState: lightState, completionHandler: { (errors: [AnyObject]!) -> () in
                    
                    if errors != nil {
                        let message = String(format: NSLocalizedString("Errors %@", comment: ""), errors)
                        NSLog("Response: \(message)")
                    }
                })
            }
        }
    }
}

