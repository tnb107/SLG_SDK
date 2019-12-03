//
//  EditUserInfoViewController.swift
//  sdk
//
//  Created by Apple on 10/2/17.
//  Copyright © 2017 slg. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire
import SVProgressHUD


public typealias EditUserInfoCompletionHandler = () -> ()
 
class EditUserInfoViewController: UIViewController {

    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var titleUILabel: UILabel!
    
    @IBOutlet weak var sexContainerView: UIView!
    
    @IBOutlet weak var sexUISegmentedControl: UISegmentedControl!
    
    public static let typesex = 1, typeaddress = 2, typeidentify = 3, typephone = 4, typeemail = 5, typebirthday = 6
    
    public var typeOfEdit: Int?;
    
    public var editUserInfoCompletionHandler: EditUserInfoCompletionHandler?
    
    var fieldName: String?
    
    var passWord: String = ""
    
    let datePicker = UIDatePicker()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sexContainerView.isHidden = true

        // Do any additional setup after loading the view.
        if typeOfEdit == EditUserInfoViewController.typephone {
            textField.placeholder = "Nhập số điện thoại"
            titleUILabel.text = "Sửa số điện thoại"
            fieldName = "phone"
            textField.keyboardType = UIKeyboardType.phonePad
            passwordTextField.placeholder = "Nhập mật khẩu"
            
        } else if typeOfEdit == EditUserInfoViewController.typesex {
            titleUILabel.text = "Chọn giới tính"
            fieldName = "sex"
            sexContainerView.isHidden = false
            textField.isHidden = true
            passwordTextField.isHidden = true
        } else if typeOfEdit == EditUserInfoViewController.typeemail {
            textField.placeholder = "Nhập địa chỉ email"
            titleUILabel.text = "Sửa email"
            fieldName = "email"
            textField.keyboardType = UIKeyboardType.emailAddress
            passwordTextField.placeholder = "Nhập mật khẩu"
        } else if typeOfEdit == EditUserInfoViewController.typeaddress {
            textField.placeholder = "Nhập địa chỉ của bạn"
            titleUILabel.text = "Sửa địa chỉ"
            fieldName = "address"
            passwordTextField.isHidden = true
        } else if typeOfEdit == EditUserInfoViewController.typebirthday {
            textField.placeholder = "Chọn ngày sinh của bạn"
            titleUILabel.text = "Sửa ngày sinh"
            fieldName = "birthday" 
            showDatePicker()
            passwordTextField.isHidden = true
        } else if typeOfEdit == EditUserInfoViewController.typeidentify {
            textField.placeholder = "Nhập số chứng minh nhân dân của bạn"
            titleUILabel.text = "Sửa số chứng minh nhân dân"
            fieldName = "identify"
            textField.keyboardType = UIKeyboardType.numberPad
            passwordTextField.placeholder = "Nhập mật khẩu"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showDatePicker(){
        //Formate Date
        datePicker.datePickerMode = .date
        
        //ToolBar
        let toolbar = UIToolbar();
        toolbar.sizeToFit()
        
        //done button & cancel button
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: self, action: #selector(donedatePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.done, target: self, action: #selector(cancelDatePicker))
        toolbar.setItems([doneButton,spaceButton,cancelButton], animated: false)
        
        // add toolbar to textField
        textField.inputAccessoryView = toolbar
        // add datepicker to textField
        textField.inputView = datePicker
        
    }
    
    @objc func donedatePicker(){
        //For date formate
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        textField.text = formatter.string(from: datePicker.date)
        //dismiss date picker dialog
        self.view.endEditing(true)
    }
    
    @objc func cancelDatePicker(){
        //cancel button dismiss datepicker dialog
        self.view.endEditing(true)
    }
 
    
    @IBAction func backClicked(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func confirmClicked(_ sender: UIButton) {
        var fieldValue: String = ""
        
        if typeOfEdit == EditUserInfoViewController.typesex {
            fieldValue = "\(sexUISegmentedControl.selectedSegmentIndex)"
        }else {
            fieldValue = textField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if typeOfEdit == EditUserInfoViewController.typeemail
            || typeOfEdit == EditUserInfoViewController.typephone
            || typeOfEdit == EditUserInfoViewController.typeidentify{
            passWord = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if fieldValue.count > 0 {
            let user: User? = Util.getCurrentUser()
            if let user = user {
                changeInformation(accessToken: user.accessToken ?? "", field: fieldName!, value: fieldValue, passWord: passWord)
            }else{
                Util.showMessage(controller: self, message: "Bạn chưa đăng nhập !")
            }
        }else {
            Util.showMessage(controller: self, message: "Vui lòng nhập dữ liệu !")
        }
    }
    
    func changeInformation(accessToken: String,field: String, value: String, passWord: String) -> Void {
        //
        var parameters: [String:Any] = [
            "access_token" : accessToken,
            field: value
        ]
        if passWord != ""{
            parameters = [
                "access_token" : accessToken,
                field: value,
                "password" : passWord
            ]
        }
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Lưu lại...")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.changeInformation, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: json)
                
                if(errorCode == 200){
                    //success
                    self.editUserInfoCompletionHandler?()
                    self.dismiss(animated: true, completion: nil)
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
