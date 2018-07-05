//
//  ViewController.swift
//  sdk
//
//  Created by Apple on 9/14/17.
//  Copyright © 2017 slg. All rights reserved.
//

import UIKit
import Alamofire
import SVProgressHUD
import SwiftyJSON
import FBSDKCoreKit
import FBSDKLoginKit 
import GoogleSignIn
class HomeViewController: UIViewController, LoginDelegate, GIDSignInUIDelegate {
    
    var delegate: LoginDelegate?

    @IBOutlet weak var lblLogin: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //lblLogin.sizeToFit()

        // Do any additional setup after loading the view.
        //Util.showMessage(controller: self, message: uuid) 
        GIDSignIn.sharedInstance().uiDelegate = self
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(receiveToggleAuthUINotification(_:)),
                                               name: NSNotification.Name(rawValue: "ToggleAuthUINotification"),
                                               object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTapLoginSLGID(_ sender: UITapGestureRecognizer) {
        DLog.log(message: "onTapLoginSLGID") 
        let bundle = Util.getSDKBundle()
        
        let slgIDLoginController: SlgIDLoginViewController = SlgIDLoginViewController(nibName: "SlgIDLoginViewController", bundle: bundle)
        slgIDLoginController.delegate = self
        self.present(slgIDLoginController, animated: true, completion: nil)
        
    }
    
    func responseLogin(issuccess: Bool,response: Any?, message: String?,errorCode: Int?, user: User?){
        self.dismiss(animated: true, completion: nil)
        delegate?.responseLogin(issuccess: issuccess, response: response, message: message, errorCode: errorCode, user: user)
    }
    
    @IBAction func onTapLoginFacebook(_ sender: UITapGestureRecognizer) {
        let facebookManager: FBSDKLoginManager = FBSDKLoginManager()
        
        facebookManager.logIn(withReadPermissions: [ "public_profile", "email" ], from: self) { (loginResult, error) in
            //
            if let error = error {
                DLog.log(message: "Unexpected login error: " + error.localizedDescription)
                Util.showMessage(controller: self, message: error.localizedDescription)
            }else {
                //let token = loginResult?.token.tokenString ?? "";
                let token = loginResult?.token
                if token != nil {
                    self.loginFacebook(facebookTokenString: token?.tokenString ?? "")
                }
            }
        }
    }
    
    func loginFacebook(facebookTokenString token: String) -> Void {
        let parameters: [String:Any] = [
            "access_token" : token,
            "client_id" : SlgSDK.shared.clientId!,
            "client_secret" : SlgSDK.shared.clientsecret!,
            "cpid" : SlgSDK.shared.cpid!,
            "os_id" : Define.osId,
            "device_id" : Util.getUUID()
        ]
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Đăng nhập")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.facebookLogin, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: json)
                
                if(errorCode == 200){
                    //login success
                    let data = json["data"].rawString() ?? ""
                    
                    //save user json to local
                    Util.saveString(key: "user", value: data)
                    
                    let user = User(JSONString: data)
                    Util.saveString(key: "accessToken", value: (user?.accessToken)!)
                    Util.saveString(key: "refreshToken", value: (user?.refreshToken)!)
                    self.dismiss(animated: true, completion: nil)
                    
                    self.delegate?.responseLogin(issuccess: true, response: value, message: message, errorCode: errorCode, user: user)
                    if let user = user {
                        Util.saveString(key: "provider", value: user.provider!)
                        if user.provider == "device"{
                            SlgSDK.shared.startTimer()
                        }else{
                            SlgSDK.shared.stopTimer()
                        }
                        print(Util.getString(key: "provider"))
                    }
                }else{
                    self.delegate?.responseLogin(issuccess: false, response: value, message: message, errorCode: errorCode, user: nil)
                    Util.showMessage(controller: self, message: message)
                }
            case .failure(let error):
                self.delegate?.responseLogin(issuccess: false, response: nil, message: error.localizedDescription, errorCode: nil, user: nil)
                Util.showMessage(controller: self,message: error.localizedDescription)
            }
            
        }
    }
    
    
    
    @IBAction func onTapPlayNow(_ sender: UITapGestureRecognizer) {
//        1. **client_id** (integer, mandatory)
//        2. **client_secret** (integer, mandatory)
//        3. **cpid** (integer, optional)
//        4. **os_id** (integer, mandatory): 1 – Android; 2 – iOS; 3 – WP
//        5. **device_id** (string, mandatory)
        
        let parameters: [String:Any] = [
            "client_id" : SlgSDK.shared.clientId!,
            "client_secret" : SlgSDK.shared.clientsecret!,
            "cp_id" : SlgSDK.shared.cpid!,
            "os_id" : Define.osId,
            "device_id": Util.getUUID()
        ]
        
        SVProgressHUD.show(withStatus: "Đăng nhập")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.deviceLogin, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: json)
                
                if(errorCode == 200){
                    //login success
                    let data = json["data"].rawString() ?? ""
                    
                    //save user json to local
                    Util.saveString(key: "user", value: data)
                    
                    let user = User(JSONString: data)
                    Util.saveString(key: "accessToken", value: (user?.accessToken)!)
                    Util.saveString(key: "refreshToken", value: (user?.refreshToken)!)
                    
                    self.dismiss(animated: true, completion: nil)
                    
                    self.delegate?.responseLogin(issuccess: true, response: value, message: message, errorCode: errorCode, user: user)
                    if let user = user {
                        Util.saveString(key: "provider", value: user.provider!)
                        if user.provider == "device"{
                            SlgSDK.shared.startTimer()
                        }else{
                            SlgSDK.shared.stopTimer()
                        }
                        print(Util.getString(key: "provider"))
                    }
                }else{
                    self.delegate?.responseLogin(issuccess: false, response: value, message: message, errorCode: errorCode, user: nil)
                    Util.showMessage(controller: self, message: message)
                }
            case .failure(let error):
                self.delegate?.responseLogin(issuccess: false, response: nil, message: error.localizedDescription, errorCode: nil, user: nil)
                Util.showMessage(controller: self,message: error.localizedDescription)
            }
            
        }
    }
 
    
    @IBAction func loginGoogle(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    @objc func receiveToggleAuthUINotification(_ notification: NSNotification) {
        if notification.name.rawValue == "ToggleAuthUINotification" {
            //            self.toggleAuthUI()
            if notification.userInfo != nil {
                guard let userInfo = notification.userInfo as? [String:String] else { return }
                let accessToken: String = userInfo["accessToken"] ?? ""
                
                let parameters: [String:Any] = [
                    "access_token" : accessToken,
                    "client_id" : SlgSDK.shared.clientId!,
                    "client_secret" : SlgSDK.shared.clientsecret!,
                    "cpid" : SlgSDK.shared.cpid!,
                    "os_id" : Define.osId,
                    "device_id" : Util.getUUID()
                ]
                
                DLog.log(message: parameters)
                
                SVProgressHUD.show(withStatus: "Đăng nhập")
                UIApplication.shared.beginIgnoringInteractionEvents()
                
                Alamofire.request(Define.googleLogin, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
                    SVProgressHUD.dismiss()
                    UIApplication.shared.endIgnoringInteractionEvents()
                    
                    switch(response.result){
                    case .success(let value):
                        let json = JSON(value)
                        let message:String = json["message"].string ?? ""
                        let errorCode:Int = json["error_code"].int ?? 0
                        
                        DLog.log(message: json)
                        
                        if(errorCode == 200){
                            //login success
                            let data = json["data"].rawString() ?? ""
                            
                            //save user json to local
                            Util.saveString(key: "user", value: data)
                            
                            let user = User(JSONString: data)
                            Util.saveString(key: "accessToken", value: (user?.accessToken)!)
                            Util.saveString(key: "refreshToken", value: (user?.refreshToken)!)
                            
                            self.dismiss(animated: true, completion: nil)
                            
                            self.delegate?.responseLogin(issuccess: true, response: value, message: message, errorCode: errorCode, user: user)
                            if let user = user {
                                Util.saveString(key: "provider", value: user.provider!)
                                if user.provider == "device"{
                                    SlgSDK.shared.startTimer()
                                }else{
                                    SlgSDK.shared.stopTimer()
                                }
                                print(Util.getString(key: "provider"))
                            }
                        }else{
                            self.delegate?.responseLogin(issuccess: false, response: value, message: message, errorCode: errorCode, user: nil)
                            Util.showMessage(controller: self, message: message)
                        }
                    case .failure(let error):
                        self.delegate?.responseLogin(issuccess: false, response: nil, message: error.localizedDescription, errorCode: nil, user: nil)
                        Util.showMessage(controller: self,message: error.localizedDescription)
                    }
                    
                }
                
            }
        }
    }
    
    @IBAction func onTapRegister(_ sender: UITapGestureRecognizer) {
        let bundle = Util.getSDKBundle()
        let registerViewController: RegisterViewController = RegisterViewController(nibName: "RegisterViewController", bundle: bundle)
        registerViewController.delegate = self
        self.present(registerViewController, animated: true, completion: nil)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "ToggleAuthUINotification"),
                                                  object: nil)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
