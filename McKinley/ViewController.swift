//
//  ViewController.swift
//  McKinley
//
//  Created by Uzair Dhada on 21/12/19.
//  Copyright © 2019 Uzair Dhada. All rights reserved.
//

import UIKit

struct Token: Codable {
    let token: String
}

class ViewController: UIViewController {
    
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var passwordTextFiled: UITextField!
    
    var token : Token?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    @IBAction func didSelectLoginButton(_ sender: Any) {
        guard let hasId = idTextField.text , let hasPassword = passwordTextFiled.text else {
            self.alert(message: "ID and Password are mandatory.", title: "")
            return
        }
        
        API.login.apiRequestData(method: .post, params: [hasId : hasPassword]) { (result : Result<Token, APIRestClient.APIServiceError>) in
            switch result {
            case .success(let token):
                self.token = token
            case .failure(let error):
                switch error {
                case .internalServerError500:
                    self.alert(message: "Internal Server Error", title: "")
                case .notFound404:
                    self.alert(message: "Not Found", title: "")
                case .validationErrors422:
                    self.alert(message: "Validation Error", title: "")
                default:
                    self.alert(message: error.localizedDescription, title: "")
                }
            }
        }
    }
    
}

