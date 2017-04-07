//
//  ProcessingViewController.swift
//  Checkout
//
//  Created by Sven Resch on 2016-06-01.
//  Copyright © 2017 Bambora Inc. All rights reserved.
//

import UIKit

class ProcessingViewController: UIViewController {
    
    @IBOutlet weak var amountLabel: UILabel!
    
    var email: String?
    var name: String?
    var number: String?
    var expiryMonth: String?
    var expiryYear: String?
    var cvd: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let amountStr = State.sharedInstance.amountStr {
            self.amountLabel.text = amountStr
        }
        NotificationCenter.default.post(name: Notification.Name(rawValue: "ShowFooter"), object: self)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: Notification.Name(rawValue: "HideFooter"), object: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let number = number, let expiryYear = expiryYear, let expiryMonth = expiryMonth, let cvd = cvd, State.sharedInstance.amountStr != nil && State.sharedInstance.processingClosure != nil
        {
            let params = ["number": number,
                          "expiry_month": expiryMonth,
                          "expiry_year": expiryYear,
                          "cvd": cvd]
            
            self.process(params)
        }
        else {
            print("ProcessingViewController was shown without needed vars!!!")
            _ = self.navigationController?.popViewController(animated: true)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    fileprivate func process(_ params: Dictionary<String, String>) {
        if let url = URL(string: "https://www.beanstream.com/scripts/tokenization/tokens") {
            
            let urlconfig = URLSessionConfiguration.default
            urlconfig.timeoutIntervalForRequest = Settings.tokenRequestTimeout
            urlconfig.timeoutIntervalForResource = Settings.tokenRequestTimeout
            
            let session = URLSession(configuration: urlconfig, delegate: self, delegateQueue: nil)
            let request = NSMutableURLRequest(url: url)
            
            var data: Data?
            
            do {
                try data = JSONSerialization.data(withJSONObject: params, options: JSONSerialization.WritingOptions(rawValue: 0))
            } catch let error as NSError {
                if let processingClosure = State.sharedInstance.processingClosure {
                    processingClosure(nil, error)
                }
                return
            }

            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            request.httpMethod = "POST"
            request.httpBody = data
            
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            
            // Force a 2 second sleep to ensure UX as the tokenization call alone is pretty fast
            Thread.sleep(forTimeInterval: 2)
            
            let task = session.dataTask(with: request as URLRequest) { data, response, err in
                
                var statusCode = 200
                var error: Error? = err
                
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                    if statusCode != 200 {
                        print("HTTP Error \(statusCode) when getting token.")
                        let userInfo = [
                            NSLocalizedDescriptionKey: HTTPURLResponse.localizedString(forStatusCode: statusCode)
                        ]
                        error = NSError(domain: "Tokenization Request Error", code: statusCode, userInfo: userInfo)
                    }
                }

                var result = Dictionary<String, AnyObject>()
                
                if let address = State.sharedInstance.shippingAddress {
                    var shippingInfo = Dictionary<String, String>()
                    shippingInfo["name"] = address.name
                    shippingInfo["address_line1"] = address.street
                    shippingInfo["postal_code"] = address.postalCode
                    shippingInfo["city"] = address.city
                    shippingInfo["province"] = address.province
                    shippingInfo["country"] = address.country
                    result["shippingAddress"] = shippingInfo as AnyObject?
                }
                
                if let address = State.sharedInstance.billingAddress {
                    var billingInfo = Dictionary<String, String>()
                    billingInfo["name"] = address.name
                    billingInfo["address_line1"] = address.street
                    billingInfo["postal_code"] = address.postalCode
                    billingInfo["city"] = address.city
                    billingInfo["province"] = address.province
                    billingInfo["country"] = address.country
                    result["billingAddress"] = billingInfo as AnyObject?
                }
                
                if error != nil {
                    if let processingClosure = State.sharedInstance.processingClosure {
                        processingClosure((result.count > 0 ? result : nil), error as NSError?)
                    }
                }
                else {
                    do {
                        let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
                        
                        if let json = json, let token = json["token"] as? String {
                            var cardInfo = Dictionary<String, String>()
                            cardInfo["code"] = token
                            cardInfo["name"] = (self.name == nil ? "" : self.name)
                            cardInfo["email"] = (self.email == nil ? "" : self.email)
                            result["cardInfo"] = cardInfo as AnyObject?
                        }
                    } catch {}
                    
                    if let processingClosure = State.sharedInstance.processingClosure {
                        processingClosure(result, nil)
                    }
                }
                
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
            
            task.resume()
        }
    }
}

extension ProcessingViewController: URLSessionDelegate {
    
}
