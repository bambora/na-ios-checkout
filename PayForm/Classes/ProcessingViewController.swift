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
    
    var amountStr: String?
    var processingClosure: ((jsonToken: Dictionary<String, AnyObject>?, error: NSError?) -> Void)?

    var number: String?
    var expiryMonth: String?
    var expiryYear: String?
    var cvd: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = ""
        self.navigationItem.setHidesBackButton(true, animated: true)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let amountStr = self.amountStr {
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
        if let number = number, let expiryYear = expiryYear, let expiryMonth = expiryMonth, let cvd = cvd where amountStr != nil && processingClosure != nil {
            let params = ["number": number,
                          "expiry_month": expiryMonth,
                          "expiry_year": expiryYear,
                          "cvd": cvd]
            
            self.process(params)
        }
        else {
            print("ProcessingViewController was shown without needed vars!!!")
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    private func process(params: Dictionary<String, String>) {
        if let url = NSURL(string: "https://www.beanstream.com/scripts/tokenization/tokens") {
            let request = NSMutableURLRequest(URL: url)
            let session = NSURLSession.sharedSession()
            
            var data: NSData?
            
            do {
                try data = NSJSONSerialization.dataWithJSONObject(params, options: NSJSONWritingOptions(rawValue: 0))
            } catch let error as NSError {
                if let processingClosure = self.processingClosure {
                    processingClosure(jsonToken: nil, error: error)
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
            
            let task = session.dataTaskWithRequest(request, completionHandler: { (data, response, error) in

                var statusCode = 200
                var httpError: NSError?
                
                if let httpResponse = response as? NSHTTPURLResponse {
                    statusCode = httpResponse.statusCode
                    if statusCode != 200 {
                        print("HTTP Error \(statusCode) when getting token.")
                        let userInfo = [
                            NSLocalizedDescriptionKey: NSHTTPURLResponse.localizedStringForStatusCode(statusCode)
                        ]
                        httpError = NSError(domain: "Tokenization Request Error", code: statusCode, userInfo: userInfo)
                    }
                }

                if httpError != nil {
                    if let processingClosure = self.processingClosure {
                        processingClosure(jsonToken: nil, error: httpError)
                    }
                }
                else if error != nil {
                    if let processingClosure = self.processingClosure {
                        processingClosure(jsonToken: nil, error: error)
                    }
                }
                else {
                    var json: Dictionary<String, AnyObject>?
                    
                    do {
                        json = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(rawValue: 0)) as? Dictionary<String, AnyObject>
                    } catch {}
                    
                    if let processingClosure = self.processingClosure {
                        processingClosure(jsonToken: json, error: nil)
                    }
                }
                
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                self.navigationController?.dismissViewControllerAnimated(true, completion: nil)
            })
            
            task.resume()
        }
    }
}
