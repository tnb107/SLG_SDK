//
//  UserInfoViewController.swift
//  sdk
//
//  Created by Apple on 9/27/17.
//  Copyright © 2017 slg. All rights reserved.
//

import UIKit
import SVProgressHUD
import SwiftyJSON
import Alamofire
import SDWebImage
import MessageUI

class UserInfoViewController: UIViewController, MFMailComposeViewControllerDelegate {
    
    //image
    @IBOutlet weak var editIdUIImageView: UIImageView!
    
    @IBOutlet weak var editSexUIImageView: UIImageView!
    
    @IBOutlet weak var editPhoneNumberUIImageView: UIImageView!
    
    @IBOutlet weak var edItidentityNumberUIImageView: UIImageView!
    
    @IBOutlet weak var editEmailUIImageView: UIImageView!
    
    @IBOutlet weak var editBirthdayUIImageView: UIImageView!
    
    @IBOutlet weak var editAddressUIImageView: UIImageView!
    
    @IBOutlet weak var editPasswordUIImageView: UIImageView!
    
    @IBOutlet weak var avatarUIImageView: UIImageView!
    
    @IBOutlet weak var coverUIImageView: UIImageView!
    
    //end image
    
    //label
    @IBOutlet weak var usernameUILabel: UILabel!
    
    @IBOutlet weak var emailUILabel: UILabel!
    
    @IBOutlet weak var birthdayUILabel: UILabel!
    
    @IBOutlet weak var addressUILabel: UILabel!
    
    @IBOutlet weak var itidentityNumberUILabel: UILabel!
    
    @IBOutlet weak var phoneNumberUILabel: UILabel!
    
    @IBOutlet weak var sexUILabel: UILabel!
    
    @IBOutlet weak var idUILabel: UILabel!
    //end label
    var dashboardCompletionHandler: DashboardCompletionHandler?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.getUserInfo()
    }
    
    func getUserInfo() -> Void {
        let user = Util.getCurrentUser()
        
        if let user = user {
            let parameters: [String:Any] = [
                "access_token" : user.accessToken ?? "",
                "client_id" : SlgSDK.shared.clientId!,
                "client_secret" : SlgSDK.shared.clientsecret!
            ]
            
            DLog.log(message: parameters)
            
            SVProgressHUD.show(withStatus: "Đang lấy thông tin")
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            let defaultData = "chưa có thông tin"
            
            Alamofire.request(Define.userInformation, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                switch(response.result){
                case .success(let value):
                    let json = JSON(value)
                    let message:String = json["message"].string ?? ""
                    let errorCode:Int = json["error_code"].int ?? 0
                    
                    DLog.log(message: "getUserInfo: \(json)")
                    
                    if(errorCode == 200){
                        //login success
                        let data = json["data"].rawString() ?? ""
                        
                        //save user json to local
                        //Util.saveString(key: "user", value: data)
                        let user = User(JSONString: data)
                        if let user = user {
                           
                            self.idUILabel.text = String(describing: user.id!)
                            self.usernameUILabel.text = user.realname ?? defaultData
                            self.sexUILabel.text = user.sex ?? defaultData
                            self.phoneNumberUILabel.text = user.phone ?? defaultData
                            self.itidentityNumberUILabel.text = user.identify ?? defaultData
                            self.emailUILabel.text = user.email ?? defaultData
                            self.birthdayUILabel.text = user.birthday ?? defaultData
                            self.addressUILabel.text =  user.address ?? defaultData
 
                            
                            self.avatarUIImageView.sd_setImage(with: URL(string: user.avatar ?? ""), placeholderImage: UIImage(named: "avatar-default.jpg", in: Util.getSDKBundle(), compatibleWith: nil))
                            
                            self.coverUIImageView.sd_setImage(with: URL(string: user.coverImage ?? ""), placeholderImage: UIImage(named: "cover-image", in: Util.getSDKBundle(), compatibleWith: nil))
                            
                            if user.email != nil {
                                self.editEmailUIImageView.isHidden = true
                            }
                            
                            if user.phone != nil {
                                self.editPhoneNumberUIImageView.isHidden = true
                            }
                            
                            if user.identify != nil {
                                self.edItidentityNumberUIImageView.isHidden = true
                            }
                            
                            self.editIdUIImageView.isHidden = true
                        }
                    }else if(errorCode == 403){
                        //user logout
                        Util.showNotification(message: "Phiên làm việc đã hết hạn, vui lòng bấm nút đăng xuất và tiến hành đăng nhập lại")
                        DLog.log(message: "Phiên làm việc đã hết hạn, vui lòng bấm nút đăng xuất và tiến hành đăng nhập lại")
                        //self.dismiss(animated: true, completion: nil)
                    }else{
                        Util.showMessage(controller: self, message: message)
                    }
                case .failure(let error):
                    Util.showMessage(controller: self,message: error.localizedDescription)
                }
                
            }
        }else{
            Util.showNotification(message: "Phiên làm việc đã hết hạn, vui lòng bấm nút đăng xuất và tiến hành đăng nhập lại")
            DLog.log(message: "Phiên làm việc đã hết hạn, vui lòng bấm nút đăng xuất và tiến hành đăng nhập lại")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonLogoutClicked(_ sender: UIButton) {
        SlgSDK.logout()
        dashboardCompletionHandler?(true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func changePasswordClicked(_ sender: UITapGestureRecognizer) {
        let bundle = Util.getSDKBundle()
        let changePasswordViewController: ChangePasswordViewController = ChangePasswordViewController(nibName: "ChangePasswordViewController", bundle: bundle)
        self.present(changePasswordViewController, animated: true, completion: nil)  
    }
    
    @IBAction func callSupportClicked(_ sender: Any) {
          let phoneNumber = "02435380202"
        
        if let url = URL(string: "tel://\(phoneNumber)"), UIApplication.shared.canOpenURL(url) {
            if #available(iOS 10, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    
    @IBAction func sendMailClicked(_ sender: Any) {
        self.sendEmail()
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["hotro@slg.vn"])
            mail.setSubject("Tôi cần hỗ trợ")
            mail.setMessageBody("<p>Nội dung cần hỗ trợ</p>", isHTML: true)
            
            present(mail, animated: true)
        } else {
            // show failure alert
            Util.showMessage(controller: self
                , message: "Không tìm được trình soạn thảo mail")
        }
    }
    
    
    @IBAction func backClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func phoneClicked(_ sender: UITapGestureRecognizer) {
        if !self.editPhoneNumberUIImageView.isHidden {
           self.openScreenEdit(type: EditUserInfoViewController.typephone)
        }
    }
    
    @IBAction func sexClicked(_ sender: UITapGestureRecognizer) {
        self.openScreenEdit(type: EditUserInfoViewController.typesex)
    }
    
    @IBAction func addressClicked(_ sender: Any) {
        self.openScreenEdit(type: EditUserInfoViewController.typeaddress)
    }
    
    @IBAction func mailClicked(_ sender: Any) {
        if !self.editEmailUIImageView.isHidden {
          self.openScreenEdit(type: EditUserInfoViewController.typeemail)
        }
    }
    
    @IBAction func birthdayClicked(_ sender: Any) {
        self.openScreenEdit(type: EditUserInfoViewController.typebirthday)
    }
    
    @IBAction func identifyClicked(_ sender: Any) {
        if !self.edItidentityNumberUIImageView.isHidden {
             self.openScreenEdit(type: EditUserInfoViewController.typeidentify)
        }
    }
    
    func openScreenEdit(type: Int?) -> Void {
        //
        let bundle = Util.getSDKBundle()
        let editUserInfoViewController: EditUserInfoViewController = EditUserInfoViewController(nibName: "EditUserInfoViewController", bundle: bundle)
        editUserInfoViewController.typeOfEdit = type
        editUserInfoViewController.editUserInfoCompletionHandler = {
            self.getUserInfo()
        }
        
        self.present(editUserInfoViewController, animated: true, completion: nil)
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
