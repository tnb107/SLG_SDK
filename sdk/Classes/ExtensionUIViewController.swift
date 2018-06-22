//
//  ExtensionUIViewController.swift
//  sdk
//
//  Created by Apple on 9/19/17.
//  Copyright © 2017 slg. All rights reserved.
//

import Foundation
import UIKit
public extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
}
