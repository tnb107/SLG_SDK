//
//  SlgSDK.swift
//  sdk
//
//  Created by Apple on 9/14/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation
import UIKit
import FBSDKCoreKit
import FirebaseCore
import FirebaseMessaging 
import UserNotifications
import StoreKit
import SVProgressHUD
import FBSDKLoginKit
import Alamofire
import SwiftyJSON
import ObjectMapper
import GoogleSignIn


public typealias InitIAPCompletionHandler = (_ success: Bool, _ products: [Product]?) -> ()
public typealias ProductsRequestCompletionHandler = (_ success: Bool, _ products: [SKProduct]?) -> ()
public typealias ProductPurchaseCompletionHandler = (_ success: Bool, _ transaction: SKPaymentTransaction) -> ()
public typealias UserLoginCompletionHandler = (_ issuccess: Bool,_ response: Any?,_ message: String?,_ errorCode: Int?,_ user: User?) -> ()
public typealias DashboardCompletionHandler = (_ isLogout: Bool) -> ()

public class SlgSDK :NSObject {
    var productsRequest: SKProductsRequest?
    var productsRequestCompletionHandler: ProductsRequestCompletionHandler?
    var productIdentifiers: Set<String> = []
    var temporaryUIViewController: UIViewController?
    var temporarydashboardCompletionHandler: DashboardCompletionHandler?
    var temporaryDashboardUIViewController: UIViewController?
    var temporaryUpdateAccountUIViewController: UIViewController?
    
    var productPurchaseCompletionHandler: ProductPurchaseCompletionHandler?
    
    
    public static let SlgSDKPurchaseNotification = "SlgSDKPurchaseNotification"
    var timer = Timer()
    
    private static var slgSDK : SlgSDK?
    public static let shared: SlgSDK = {
        if let slgSDK = slgSDK {
            return slgSDK
        }else{
            //Messaging.messaging().subscribe(toTopic: "/topics/slg")
            slgSDK = SlgSDK()
            return slgSDK!
        }
    }()
    
    public var clientId: String?
    public var clientsecret: String?
    public var cpid: String?
    
    private var _products = [Product]()
    public var listItemsIAP = [JSON]()
    public var _debugMode: Bool = false
    
    private override init(){
        super.init()
        //start init payment
        SKPaymentQueue.default().add(self)
    }
    
    public func initIAP(clientId: String,initIAPCompletionHandler: InitIAPCompletionHandler?){
        Alamofire.request(Define.productApple, method: .post, parameters: ["client_id" : clientId, "os_id" : Define.osId], encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                //let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: Define.productApple)
                DLog.log(message: json)
                
                let data = json["data"]
                
                if(errorCode == 200){
                    let ps = Mapper<Product>().mapArray(JSONString: data.rawString() ?? "")
                    self.listItemsIAP = data.arrayValue
                    guard let productApples = ps else {
                        initIAPCompletionHandler?(false, nil)
                        return
                    }
                    
                    //add product id
                    for item in data.arrayValue {
                        DLog.log(message: "productApple: \(item)")
                        self.addProductId(productId: item["product_id"].string ?? "")
                    }
                    
                    //request product
                    self.requestProducts { (success, products) in
                        //
                        DLog.log(message: "request product: \(success)")
                        if success, let products = products {
                            for product in products {
                                for productApple in productApples {
                                    if product.productIdentifier == productApple.productId {
                                        productApple.skProduct = product
                                        break
                                    }
                                }
                            }
                            DLog.log(message: "request product success: \(productApples)")
                            self._products = productApples
                        }
                        
                        initIAPCompletionHandler?(success, productApples)
                    }
                }else{
                    initIAPCompletionHandler?(false, nil)
                }
            case .failure(let error):
                initIAPCompletionHandler?(false, nil)
                DLog.log(message: "failure: \(error.localizedDescription)")
            }
        }
        //end init payment
    }
    
    public func initIAP(clientId: String){
        self.initIAP(clientId: clientId, initIAPCompletionHandler: nil)
    }
    
    public var debugMode: Bool {
        set {
            self._debugMode = newValue
            DLog.isDebug = newValue
        }
        
        get {
            return self._debugMode
        }
    }
    
    public var products: [Product] {
        return self._products
    }
    
    public func login(_ uiViewController: UIViewController, delegate: LoginDelegate?){
        temporaryUpdateAccountUIViewController = uiViewController
        let bundle = Util.getSDKBundle()
        let homeViewController: HomeViewController = HomeViewController(nibName: "HomeViewController", bundle: bundle)
        homeViewController.delegate = delegate
        uiViewController.present(homeViewController, animated: true, completion: nil)
    }
    
    public func openDashBoard(_ uiViewController: UIViewController?,callBackDialogDissmiss dashboardCompletionHandler: DashboardCompletionHandler?){
        let bundle = Util.getSDKBundle()
        
        let userInfoViewController: UserInfoViewController = UserInfoViewController(nibName: "UserInfoViewController", bundle: bundle)
        userInfoViewController.dashboardCompletionHandler = dashboardCompletionHandler
        if let uiViewController = uiViewController {
            uiViewController.present(userInfoViewController, animated: true, completion: nil)
        }
    }
    
    public func validateCurrentAccessToken(uiViewController: UIViewController, userLoginCompletionHandler:  UserLoginCompletionHandler?){
        
        let user = Util.getCurrentUser()
        
        if let user = user {
            let parameters: [String:Any] = [
                "access_token" : user.accessToken ?? ""
            ]
            
            DLog.log(message: parameters)
            
            SVProgressHUD.show(withStatus: "đang kiểm tra...")
            UIApplication.shared.beginIgnoringInteractionEvents()
            
            Alamofire.request(Define.validateAccessToken, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                
                switch(response.result){
                case .success(let value):
                    let json = JSON(value)
                    let message:String = json["message"].string ?? ""
                    let errorCode:Int = json["error_code"].int ?? 0
                    
                    DLog.log(message: json)
                    
                    if(errorCode == 200){
                        Util.showNotification(message: "Xin chào \(user.username ?? "bạn")")
                        userLoginCompletionHandler?(true, value, message, errorCode, user)
                    }else{
                        Util.showNotification(message: message)
                        userLoginCompletionHandler?(false, value, message, errorCode, nil)
                    }
                case .failure(let error):
                    userLoginCompletionHandler?(false, nil, error.localizedDescription, nil, nil)
                    Util.showMessage(controller: uiViewController,message: error.localizedDescription)
                }
                
            }
        }else { 
            userLoginCompletionHandler?(false, nil, "Bạn chưa đăng nhập !", nil, nil)
        }
    }
    
    public func showAssistiveTouch(uiViewController: UIViewController,dashboardCompletionHandler:  DashboardCompletionHandler?){
        temporarydashboardCompletionHandler = dashboardCompletionHandler
        temporaryDashboardUIViewController = uiViewController
        
        let assistiveTouch = AssistiveTouch(frame: CGRect(x: 10, y: 100, width: 56, height: 56))
        assistiveTouch.addTarget(self, action: #selector(self.tapAssistiveTouch(sender:)), for: .touchUpInside)
        assistiveTouch.setImage(UIImage(named: "ic_assistive_touch", in: Util.getSDKBundle(), compatibleWith: nil), for: .normal)
        uiViewController.view.addSubview(assistiveTouch)
    }
    
    @objc public func tapAssistiveTouch(sender: UIButton) { 
        self.openDashBoard(temporaryDashboardUIViewController, callBackDialogDissmiss: temporarydashboardCompletionHandler)
    }
    
    public static func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Void { 
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        FirebaseApp.configure()
    }
    
    public static func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            DLog.log(message: "\(error.localizedDescription)")
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "ToggleAuthUINotification"), object: nil, userInfo: nil)
        } else {
            // Perform any operations on signed in user here.
            let userId: String = user.userID                  // For client-side use only!
            let idToken: String = user.authentication.idToken // Safe to send to the server
            let fullName: String = user.profile.name
            let givenName: String = user.profile.givenName
            let familyName: String = user.profile.familyName
            let email: String = user.profile.email
            
            NotificationCenter.default.post(
                name: Notification.Name(rawValue: "ToggleAuthUINotification"),
                object: nil,
                userInfo: ["userID": userId,
                           "idToken": idToken,
                           "fullName": fullName,
                           "givenName": givenName,
                           "familyName": familyName,
                           "email": email,
                           "accessToken": signIn.currentUser.authentication.accessToken])
        }
    }
    
    //
    @available(iOS 10.0, *)
    public static func registerNotification(application: UIApplication, messageDelegate: MessagingDelegate?,unUserNotificationCenterDelegate: UNUserNotificationCenterDelegate?){
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = messageDelegate
        // [END set_messaging_delegate]
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        
        // For iOS 10 display notification (sent via APNS)
        UNUserNotificationCenter.current().delegate = unUserNotificationCenterDelegate
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        
        application.registerForRemoteNotifications()
        
        // [END register_for_notifications]
    }
    
    public static func registerNotification2(application: UIApplication, messageDelegate: MessagingDelegate?){
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = messageDelegate
        // [END set_messaging_delegate]
        // Register for remote notifications. This shows a permission dialog on first run, to
        // show the dialog at a more appropriate time move this registration accordingly.
        // [START register_for_notifications]
        
        let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
        application.registerUserNotificationSettings(settings)
        
        
        application.registerForRemoteNotifications()
        
        // [END register_for_notifications]
    }
    
    
    public static func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool { 
        if GIDSignIn.sharedInstance().handle(url, sourceApplication: sourceApplication, annotation: annotation) {
            return true
        } else if FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: application) {
            return true
        }
        return false
    }
    
    
    public static func activateApp(){
        FBSDKAppEvents.activateApp()
    }
    
    
    public static func configureFCM(messagingDelegate: MessagingDelegate){
        // [START set_messaging_delegate]
        Messaging.messaging().delegate = messagingDelegate
        // [END set_messaging_delegate]
    }
    
    public static func logout(){
        Util.saveString(key: "user", value: "")
        FBSDKLoginManager().logOut()
        GIDSignIn.sharedInstance().signOut()
    }
    
    public func checkRefreshToken() -> Bool{
        let date = Date()
        let day = Calendar.current.component(.day, from: date)
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)
        let dateNew = String(day)+"-"+String(month)+"-"+String(year)
        let dateOld = Util.getString(key: "dateRefreshToken")
        if(dateOld == dateNew){
            return false;
        }else{
            Util.saveString(key: "dateRefreshToken", value: dateNew)
            return true;
        }
    }
}

extension SlgSDK {
    
    
    
    
    public func getReceipt() -> String?{
        do{
            let appStoreReceiptURL = Bundle.main.appStoreReceiptURL
            DLog.log(message: "appStoreReceiptURL: \(appStoreReceiptURL!)")
            
            if let url = appStoreReceiptURL {
                let receipt: Data = try Data(contentsOf: url)
                let receiptData = receipt.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
                DLog.log(message: "receiptData: " + receiptData)
                return receiptData
            }
        }catch {
            DLog.log(message: "ERROR: " +  error.localizedDescription)
        }
        
        return nil
    }
    
    public func requestProducts(completionHandler: @escaping ProductsRequestCompletionHandler) {
        productsRequest?.cancel()
        productsRequestCompletionHandler = completionHandler
        
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest!.delegate = self
        productsRequest!.start()
    }
    
    public func addProductId(productId: String) {
        let result = productIdentifiers.insert(productId)
        DLog.log(message: "addProductId: \(result)")
    }
    
    
    public func buyProduct(productId : String, server_id: Int, uiViewController: UIViewController, productPurchaseCompletionHandler: @escaping ProductPurchaseCompletionHandler){
        Define.server_id = server_id
        print("productId: \(productId)")
        guard let _ = Util.getCurrentUser() else {
            //
            Util.showMessage(controller: uiViewController, message: "Bạn chưa đăng nhập\n\nVui lòng đăng nhập để thực hiện hành động này")
            return
        }
        
        self.temporaryUIViewController = uiViewController
        self.productPurchaseCompletionHandler = productPurchaseCompletionHandler
        
        for product in products{
            if product.productId == productId{
                print(product.productId ?? "=====")
                if let skProduct = product.skProduct {
                    let payment = SKPayment(product: skProduct)
                    SKPaymentQueue.default().add(payment)
                    break
                }
            }
        }
        
        
    }
    
    public class func canMakePayments() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }
    
    public func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
}

extension SlgSDK : SKProductsRequestDelegate {
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        DLog.log(message: "Loaded list of products...")
        productsRequestCompletionHandler?(true, products)
        clearRequestAndHandler()
        
        for p in products {
            DLog.log(message: "Found product: \(p.productIdentifier) \(p.localizedTitle) \(p.price.floatValue)")
        }
    }
    
    private func clearRequestAndHandler() {
        productsRequest = nil
        productsRequestCompletionHandler = nil
    }
    
}

extension SlgSDK : SKPaymentTransactionObserver {
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        
        
        for transaction in transactions {
            switch (transaction.transactionState) {
            case .purchased:
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                complete(transaction: transaction)
                break
            case .failed:
                SVProgressHUD.dismiss()
                UIApplication.shared.endIgnoringInteractionEvents()
                fail(transaction: transaction)
                break
            case .restored:
                restore(transaction: transaction)
                break
            case .deferred:
                DLog.log(message: "paymentQueue .deferred")
                break
            case .purchasing:
                DLog.log(message: "paymentQueue .purchasing")
                SVProgressHUD.show()
                UIApplication.shared.beginIgnoringInteractionEvents()
                break
            }
        }
        
        
        
        //self.productPurchaseCompletionHandler = nil
    }
    
    private func complete(transaction: SKPaymentTransaction) {
        
        DLog.log(message: "complete... \(transaction.payment.productIdentifier)")
        deliverPurchaseNotificationFor(identifier: transaction.payment.productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
        
        let parameters: [String:Any] = [
            "access_token" : Util.getAccessToken(),
            "receipt" : self.getReceipt() ?? "",
            "cp_id" : self.cpid ?? "",
            "server_id" : Define.server_id,
            "client_id" : self.clientId ?? ""
            
        ]
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Xác nhận...")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.verifyiap, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                let message:String = json["message"].string ?? ""
                let errorCode:Int = json["error_code"].int ?? 0
                
                DLog.log(message: "transaction complete: \(json)")
                
                if (errorCode == 200){
                    self.productPurchaseCompletionHandler?(true, transaction)
                }else{
                    self.productPurchaseCompletionHandler?(false, transaction)
                    if let uiViewController = self.temporaryUIViewController {
                        Util.showMessage(controller: uiViewController, message: message)
                    }
                }
            case .failure(let error):
                self.productPurchaseCompletionHandler?(false, transaction)
                if let uiViewController = self.temporaryUIViewController {
                    Util.showMessage(controller: uiViewController, message: error.localizedDescription)
                }
            }
            self.productPurchaseCompletionHandler = nil
        }
        
        self.productPurchaseCompletionHandler = nil
    }
    
    //    private func verifyiap(){
    //
    //    }
    
    private func restore(transaction: SKPaymentTransaction) {
        guard let productIdentifier = transaction.original?.payment.productIdentifier else { return }
        
        DLog.log(message: "restore... \(productIdentifier)")
        deliverPurchaseNotificationFor(identifier: productIdentifier)
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        DLog.log(message: "fail...")
        if let transactionError = transaction.error as NSError? {
            let message:String = "Transaction Error (code \(transactionError.code)): \(transaction.error?.localizedDescription ?? "unknown error")";
            DLog.log(message: message)
            if let uiViewController = self.temporaryUIViewController {
                Util.showMessage(controller: uiViewController, message: message)
            } 
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
        self.productPurchaseCompletionHandler?(false, transaction)
        self.productPurchaseCompletionHandler = nil
    }
    
    private func deliverPurchaseNotificationFor(identifier: String?) {
        guard let identifier = identifier else { return }
        
        //UserDefaults.standard.set(true, forKey: identifier)
        //UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: SlgSDK.SlgSDKPurchaseNotification), object: identifier)
    }
    
    
    public func startTimer() -> Void {
        timer.invalidate() // just in case this button is tapped multiple times
        
        // start the timer
        timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
    }
    
    public func stopTimer() -> Void {
        timer.invalidate()
    }
    
    @objc public func timerAction() -> Void {
        print("show popup update account")
        if Util.getString(key: "provider") != "device_registered"{
            let refreshAlert = UIAlertController(title: "Thông báo", message: "Bạn đang dùng tài khoản chơi ngay, bạn có muốn nâng cấp để chơi được trên nhiều thiết bị không?", preferredStyle: UIAlertControllerStyle.alert)
            
            refreshAlert.addAction(UIAlertAction(title: "Nâng cấp", style: .default, handler: { (action: UIAlertAction!) in
                print("Handle Ok logic here")
                let bundle = Util.getSDKBundle()
                let updateAccountViewController: UpdateAccountViewController = UpdateAccountViewController(nibName: "UpdateAccountViewController", bundle: bundle)
                if let uiViewController = self.temporaryUpdateAccountUIViewController {
                    uiViewController.present(updateAccountViewController, animated: true, completion: nil)
                }
            }))
            
            refreshAlert.addAction(UIAlertAction(title: "Huỷ bỏ", style: .cancel, handler: { (action: UIAlertAction!) in
                
            }))
            if let uiViewController = temporaryUpdateAccountUIViewController {
                uiViewController.present(refreshAlert, animated: true, completion: nil)
            }
        }
    }
    
    public func saveFirebaseToken(token : String) -> Void {
        
        let parameters: [String:Any] = [
            "access_token" : Util.getAccessToken(),
            "token" : token,
            "cp_id" : self.cpid ?? "",
            "client_id" : self.clientId ?? ""
        ]
        
        DLog.log(message: parameters)
        
        SVProgressHUD.show(withStatus: "Save Firebase Token...")
        UIApplication.shared.beginIgnoringInteractionEvents()
        
        Alamofire.request(Define.saveFirebaseToken, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: nil).responseJSON { (response) in
            SVProgressHUD.dismiss()
            UIApplication.shared.endIgnoringInteractionEvents()
            
            switch(response.result){
            case .success(let value):
                let json = JSON(value)
                
                DLog.log(message: "Save complete: \(json)")
                
            case .failure(let error):
                if let uiViewController = self.temporaryUIViewController {
                    Util.showMessage(controller: uiViewController, message: error.localizedDescription)
                }
            }
            self.productPurchaseCompletionHandler = nil
        }
        
        self.productPurchaseCompletionHandler = nil
    }
    
    public func getListItemIAP() -> [JSON] {
        return listItemsIAP
    }
}
