//
//  UpdateAccount.swift
//  Alamofire
//
//  Created by thanhnb on 7/2/18.
//

import UIKit
import SVProgressHUD
import SwiftyJSON
import Alamofire

class UpdateAccountViewController: UIViewController {
    
    
    @IBOutlet weak var emailUITextField: UITextField!
    
    @IBOutlet weak var passwordUITextField: UITextField!
    
    @IBOutlet weak var reenterPasswordUITextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonBackClicked(_ sender: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func buttonConfirmClicked(_ sender: Any) {
        //request api change password
        let email: String = emailUITextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password: String = passwordUITextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let password_confirmation: String = reenterPasswordUITextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if email.count > 0 && password.count > 0 && password_confirmation.count  > 0 {
            print(password_confirmation)
            print(password)
            if password_confirmation == password {
                let accessToken = Util.getString(key: "accessToken")
                if accessToken != "" {
                    self.requestUpdateAccount(accessToken: accessToken, email: email, password: password, password_confirmation: password_confirmation, retry: false)
                }else{
                    Util.showMessage(controller: self, message: "Bạn chưa đăng nhâp !")
                }
            }else {
                Util.showMessage(controller: self, message: "Mật khẩu nhập lại không khớp")
            }
        }else {
            Util.showMessage(controller: self, message: "Vui lòng nhập đầy đủ thông tin")
        }
    }
    
//    func updateAccount(accessToken: String, oldPassword: String, newPassword: String, new_password_confirmation : String){
//        //
//
//        requestChangePassword(accessToken: accessToken, oldPassword: oldPassword, newPassword: newPassword, new_password_confirmation: new_password_confirmation, retry: false)
//
//        SVProgressHUD.show(withStatus: "Đang đổi mật khẩu")
//        UIApplication.shared.beginIgnoringInteractionEvents()
//
//
//    }
    func requestUpdateAccount(accessToken: String, email: String, password: String, password_confirmation : String, retry : Bool)->Void{
        let parameters: [String:Any] = [
            "access_token" : accessToken,
            "email" : email,
            "password" : password,
            "password_confirmation" : password_confirmation
        ]
        DLog.log(message: parameters)
        Alamofire.request(Define.updateAccount, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: "updateAccount: \(json)")
                
                if(errorCode == 200){
                    Util.showNotification(message: "Nâng cấp tài khoản thành công")
                    Util.saveString(key: "provider", value: "device_registered")
                    self.emailUITextField.text = ""
                    self.passwordUITextField.text = ""
                    self.reenterPasswordUITextField.text = ""
                    self.dismiss(animated: true, completion: nil)
                }
                else if(errorCode == 803 && !retry){
                    self.refreshToken(email: email, password: password, password_confirmation: password_confirmation)
                }
                else{
                    Util.showMessage(controller: self, message: message)
                }
            case .failure(let error):
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
    private func refreshToken(email: String, password: String, password_confirmation : String) -> Void {
        let parameters: [String:Any] = [
            "refresh_token" : Util.getString(key: "refreshToken"),
            "client_id" : SlgSDK.shared.clientId!,
            "client_secret" : SlgSDK.shared.clientsecret!,
            "cp_id" : SlgSDK.shared.cpid!,
            "os_id" : Define.osId
        ]
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Refresh Token")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.refreshToken, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: json)
                
                if(errorCode == 200){
                    let data = json["data"]
                    let accessToken = data["access_token"].string ?? ""
                    let refreshToken = data["refresh_token"].string ?? ""
                    let parameters: [String:Any] = [
                        "access_token" : accessToken,
                        "email" : email,
                        "password" : password,
                        "password_confirmation" : password_confirmation
                    ]
                    Util.saveString(key: "accessToken", value: accessToken)
                    Util.saveString(key: "refreshToken", value: refreshToken)
                    DLog.log(message: parameters)
                    
                    SVProgressHUD.show(withStatus: "Đang lấy thông tin")
                    UIApplication.shared.beginIgnoringInteractionEvents()
                    
                    self.requestUpdateAccount(accessToken: accessToken, email: email, password: password, password_confirmation: password_confirmation, retry: true)
                    //self.dismiss(animated: true, completion: nil)
                    
                }else{
                    Util.showMessage(controller: self, message: message)
                }
            case .failure(let error):
                Util.showMessage(controller: self,message: error.localizedDescription)
            }
            
        }
    }
}
