//
//  ViewController.swift
//  sdk
//
//  Created by dieppn on 11/10/2017.
//  Copyright (c) 2017 dieppn. All rights reserved.
//

import UIKit
import sdk
class ViewController: UIViewController, LoginDelegate {
    
    let slgSDK:SlgSDK = SlgSDK.shared
    
    
    var didLayoutSubviews = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("===viewDidLoad==")
        // Do any additional setup after loading the view, typically from a nib.
        
        slgSDK.clientId = "3898128143"
        slgSDK.clientsecret = "DGO1r7r2G0SSdULXEsyk"
        slgSDK.cpid = "300000202"
        slgSDK.initIAP(clientId: slgSDK.clientId!)
        //very important. set debugMode = false when upload to apple store. set debugMode = true in development it will activate log and in app purchase
        slgSDK.debugMode = true
        slgSDK.showAssistiveTouch(uiViewController: self) { (isLogout) in
            //
            if isLogout {
                //do what u want
                print("showAssistiveTouch \(isLogout)")
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("===viewDidLayoutSubviews==")
        if(self.slgSDK.checkRefreshToken()){
            if !didLayoutSubviews {
                //now i'm going to check last session still alive
                self.slgSDK.validateCurrentAccessToken(uiViewController: self, userLoginCompletionHandler: { (issuccess, response, message, errorCode, user) in
                    //
                    if issuccess {
                        // do somethings here
                    }else {
                        // call login screen
                        //self.slgSDK.login(self, delegate: self)
                    }
                })
                
                didLayoutSubviews = true
            }
        }else{
            print("hom nay da refresh token roi")
        }
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonClicked(_ sender: Any) {
        print("buttonClicked")
        slgSDK.login(self, delegate: self)
    }
    
    @IBAction func buttonBuyClicked(_ sender: UIButton) {
        // get product list self.slgSDK.products
        debugPrint("Product list: \(self.slgSDK.products)")
        
        //now i'm going to try buy fisrt item
        if let skProduct = self.slgSDK.products.first?.skProduct {
            DLog.log(message: "buttonBuyClicked: \(skProduct)")
            slgSDK.buyProduct(skProduct, uiViewController: self, productPurchaseCompletionHandler: { (success, transaction) in
                //
                if success {
                    //you can do what u want
                }
            })
        }
    }
    
    @IBAction func buttonRestorePurchaseClicked(_ sender: UIButton) {
        slgSDK.restorePurchases()
    }
    
    @IBAction func buttonShowUserInfoClicked(_ sender: Any) {
        slgSDK.openDashBoard(self) { (isLogout) in
            //
            if isLogout {
                //user has been logged out
                print("openDashBoard \(isLogout)")
            }
        }
    }
    
    @IBAction func buttonLogoutClicked(_ sender: UIButton) {
        SlgSDK.logout()
    }
    
    func responseLogin(issuccess: Bool,response: Any?, message: String?,errorCode: Int?, user: User?){
        if issuccess {
            //Login success so some thing here
            print("Login success " + (user?.toJSONString(prettyPrint: true))!)
        }else {
        }
    }
    
}

