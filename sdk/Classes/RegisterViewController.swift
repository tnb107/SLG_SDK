//
//  RegisterViewController.swift
//  sdk
//
//  Created by Apple on 9/19/17.
//  Copyright © 2017 slg. All rights reserved.
//

import UIKit
import SVProgressHUD
import Alamofire
import SwiftyJSON

class RegisterViewController: UIViewController {

    @IBOutlet weak var uiScrollView: UIScrollView!
    
    @IBOutlet weak var uiTextFieldUserName: UITextField!
    
    @IBOutlet weak var uiTextFieldPassword: UITextField!
    
    @IBOutlet weak var uiTextFieldRePassword: UITextField!
    
    @IBOutlet weak var uiTextFieldEmail: UITextField!
    
    var delegate: LoginDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.hideKeyboardWhenTappedAround()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name:UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name:UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    
    @objc func keyboardWillShow(notification:NSNotification){
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.uiScrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        uiScrollView.contentInset = contentInset
    }
    
    @objc func keyboardWillHide(notification:NSNotification){
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        uiScrollView.contentInset = contentInset
    }
    
    @IBAction func onTapUIImageViewBack(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func onTapUIButtonRegister(_ sender: Any) {
        self.register()
    }
    
    func register() -> Void {
        //do register here
        //Util.showMessage(controller: self, message: "Do register")
        let userName: String = uiTextFieldUserName.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password: String = uiTextFieldPassword.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let rePassword: String = uiTextFieldRePassword.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let email: String = uiTextFieldEmail.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        
        if userName.isEmpty {
            Util.showMessage(controller: self, message: "Bạn chưa nhập tài khoản !")
            return
        }
        
        if password.isEmpty {
            Util.showMessage(controller: self, message: "Bạn chưa nhập mật khẩu !")
            return
        }
        
        if rePassword.isEmpty {
            Util.showMessage(controller: self, message: "Bạn chưa nhập lại mật khẩu !")
            return
        }
        
        if password != rePassword {
            Util.showMessage(controller: self, message: "Nhập lại mật khẩu không chính xác !")
            return
        }
        
        if email.isEmpty {
            Util.showMessage(controller: self, message: "Bạn chưa nhập email !")
            return
        }
        
        if !email.isValidEmail() {
            Util.showMessage(controller: self, message: "Bạn nhập email không hợp lệ !")
            return
        }
        
        
//        1. **username** (string): a-z A-Z 0-9 and "" character, length min 6 and max 255 
//        2. **password** (string): only a-z 0-9 character, length min 6
//        3. **password_confirmation** : retype to compare width password
//        4. **client_id** (string): client id
//        5. **client_secret** (string): client secret
//        6. **email** :**email**
//        7. **cpid** : (option ) cpid of each app / game
//        8. **os_id** (integer, optional): 1 – Android; 2 – iOS; 3 – WP
//        9. **device_id** (string, optional)
        
        let parameters: [String:Any] = [
            "username" : userName,
            "password" : password,
            "password_confirmation" : rePassword,
            "client_id" : SlgSDK.shared.clientId!,
            "client_secret" : SlgSDK.shared.clientsecret!,
            "email" : email,
            "cp_id" : SlgSDK.shared.cpid!,
            "os_id" : Define.osId,
            "device_id" : Util.getUUID()
        ]

        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Đăng ký")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.register, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
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
                    Util.saveString(key: "userName", value: userName)
                    Util.saveString(key: "passWord", value: password)
                    let user = User(JSONString: data)
                    Util.saveString(key: "accessToken", value: (user?.accessToken)!)
                    Util.saveString(key: "refreshToken", value: (user?.refreshToken)!)
                    self.dismiss(animated: true, completion: nil)
                    
                    self.delegate?.responseLogin(issuccess: true, response: value, message: message, errorCode: errorCode, user: user) 
                }else{
                    //self.delegate?.responseLogin(issuccess: false, response: value, message: message, errorCode: errorCode, user: nil)
                    Util.showMessage(controller: self, message: message)
                }
            case .failure(let error):
                //self.delegate?.responseLogin(issuccess: false, response: nil, message: error.localizedDescription, errorCode: nil, user: nil)
                Util.showMessage(controller: self,message: error.localizedDescription)
            }
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
