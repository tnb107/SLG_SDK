//
//  SlgIDLoginViewController.swift
//  sdk
//
//  Created by Apple on 9/18/17.
//  Copyright © 2017 slg. All rights reserved.
//

import UIKit
import Alamofire
import SVProgressHUD
import SwiftyJSON


class SlgIDLoginViewController: UIViewController {
    
    
    var delegate: LoginDelegate?
    
    
    @IBOutlet weak var uiTextFieldUserName: UITextField!

    @IBOutlet weak var uiTextFieldPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.hideKeyboardWhenTappedAround()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onTapUIImageViewBack(_ sender: Any) {
        DLog.log(message: "onTapUIImageViewBack")
        self.dismiss(animated: true, completion: nil) 
    }
    
    
    @IBAction func onTapUIButtonLogin(_ sender: Any) {
        DLog.log(message: "onTapUIButtonLogin")
        let userName = uiTextFieldUserName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = uiTextFieldPassword.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if userName.count > 0 && password.count > 0  {
            self.login(userName: userName, password: password)
        }else {
            Util.showMessage(controller: self,message: "Tài khoản, mật khẩu không được bỏ trống")
        }
    }
    
    @IBAction func onTapUILabelForgotPassword(_ sender: Any) {
        DLog.log(message: "onTapUILabelForgotPassword")
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(URL(string: "https://id.slg.vn/password/email")!, options: [:], completionHandler: nil)
        } else {
            // Fallback on earlier versions
        } 
    }
    
    private func login(userName: String, password: String) -> Void {
//        1. **username (email or username)** (string): email or username using to login 
//        2. **password** (string): password of game
//        3. **client_id** (string): id of game
//        4. **client_secret** (string): secret string of game
//        5. **cpid** (string): (optional) cpid of each app / game
//        6. **os_id** (integer, optional): 1 – Android; 2 – iOS; 3 – WP 7. **cpid** (string, optional)
        
        let parameters: [String:Any] = [
            "username" : userName,
            "password" : password,
            "client_id" : SlgSDK.shared.clientId!,
            "client_secret" : SlgSDK.shared.clientsecret!,
            "cpid" : SlgSDK.shared.cpid!,
            "os_id" : Define.osId
        ] 
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Đăng nhập")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.login, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
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
                    
                    self.dismiss(animated: true, completion: nil)
                    
                    self.delegate?.responseLogin(issuccess: true, response: value, message: message, errorCode: errorCode, user: user)
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
