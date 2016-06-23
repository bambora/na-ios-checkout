//
//  ProcessingViewController.swift
//  PayForm
//
//  Created by Sven Resch on 2016-06-01.
//  Copyright © 2016 Beanstream Internet Commerce, Inc. All rights reserved.
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
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let amountStr = State.sharedInstance.amountStr {
            self.amountLabel.text = amountStr
        }
        NSNotificationCenter.defaultCenter().postNotificationName("ShowFooter", object: self)
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().postNotificationName("HideFooter", object: self)
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let number = number, let expiryYear = expiryYear, let expiryMonth = expiryMonth, let cvd = cvd
            where State.sharedInstance.amountStr != nil && State.sharedInstance.processingClosure != nil
        {
            let params = ["number": number,
                          "expiry_month": expiryMonth,
                          "expiry_year": expiryYear,
                          "cvd": cvd]
            
            self.process(params)
        }
        else {
            print("ProcessingViewController was shown without needed vars!!!")
            self.navigationController?.popViewControllerAnimated(true)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    private func process(params: Dictionary<String, String>) {
        if let url = NSURL(string: "https://www.beanstream.com/scripts/tokenization/tokens") {
            
            let urlconfig = NSURLSessionConfiguration.defaultSessionConfiguration()
            urlconfig.timeoutIntervalForRequest = Settings.tokenRequestTimeout
            urlconfig.timeoutIntervalForResource = Settings.tokenRequestTimeout
            
            let session = NSURLSession(configuration: urlconfig, delegate: self, delegateQueue: nil)
            let request = NSMutableURLRequest(URL: url)
            
            var data: NSData?
            
            do {
                try data = NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions(rawValue: 0))
            } catch let error as NSError {
                if let processingClosure = State.sharedInstance.processingClosure {
                    processingClosure(result: nil, error: error)
                }
                return
            }

            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("application/json", forHTTPHeaderField: "Accept")

            request.HTTPMethod = "POST"
            request.HTTPBody = data
            
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            
            // Force a 2 second sleep to ensure UX as the tokenization call alone is pretty fast
            NSThread.sleepForTimeInterval(2)
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, err) in
                
                var statusCode = 200
                var error: NSError? = err
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    statusCode = httpResponse.statusCode
                    if statusCode != 200 {
                        print("HTTP Error \(statusCode) when getting token.")
                        let userInfo = [
                            NSLocalizedDescriptionKey: NSHTTPURLResponse.localizedStringForStatusCode(statusCode)
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
                    result["shippingAddress"] = shippingInfo
                }
                
                if let address = State.sharedInstance.billingAddress {
                    var billingInfo = Dictionary<String, String>()
                    billingInfo["name"] = address.name
                    billingInfo["address_line1"] = address.street
                    billingInfo["postal_code"] = address.postalCode
                    billingInfo["city"] = address.city
                    billingInfo["province"] = address.province
                    billingInfo["country"] = address.country
                    result["billingAddress"] = billingInfo
                }
                
                if error != nil {
                    if let processingClosure = State.sharedInstance.processingClosure {
                        processingClosure(result: (result.count > 0 ? result : nil), error: error)
                    }
                }
                else {
                    do {
                        let json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
                        
                        if let json = json, let token = json["token"] as? String {
                            var cardInfo = Dictionary<String, String>()
                            cardInfo["code"] = token
                            cardInfo["name"] = (self.name == nil ? "" : self.name)
                            cardInfo["email"] = (self.email == nil ? "" : self.email)
                            result["cardInfo"] = cardInfo
                        }
                    } catch {}
                    
                    if let processingClosure = State.sharedInstance.processingClosure {
                        processingClosure(result: result, error: nil)
                    }
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
            
            task.resume()
        }
    }
}

extension ProcessingViewController: NSURLSessionDelegate {
    
}
