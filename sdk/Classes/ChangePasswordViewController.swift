//
//  ChangePasswordViewController.swift
//  sdk
//
//  Created by Apple on 9/28/17.
//  Copyright © 2017 slg. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON
import Alamofire

class ChangePasswordViewController: UIViewController {
    
    
    @IBOutlet weak var oldPasswordUITextField: UITextField!
    
    @IBOutlet weak var newPasswordUITextField: UITextField!
    
    @IBOutlet weak var reenterNewPasswordUITextField: UITextField!
    
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
        let oldPassword: String = oldPasswordUITextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let newPassword: String = newPasswordUITextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        let reenterNewPassword: String = reenterNewPasswordUITextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if oldPassword.count > 0 && newPassword.count > 0 && reenterNewPassword.count  > 0 {
            if reenterNewPassword == newPassword {
                let user: User? = Util.getCurrentUser()
                if let user = user {
                    self.changePassword(accessToken: user.accessToken ?? "", oldPassword: oldPassword, newPassword: newPassword)
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
    
    func changePassword(accessToken: String, oldPassword: String, newPassword: String){
        //
        let parameters: [String:Any] = [
            "access_token" : accessToken,
            "oldpass" : oldPassword,
            "newpass" : newPassword
        ]
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Đang đổi mật khẩu")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.changePass, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: "changePassword: \(json)")
                
                if(errorCode == 200){
                    Util.showNotification(message: "Đổi mật khẩu thành công")
                    self.oldPasswordUITextField.text = ""
                    self.newPasswordUITextField.text = ""
                    self.reenterNewPasswordUITextField.text = ""
                }else{
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

}
