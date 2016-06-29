<img src="http://www.beanstream.com/wp-content/uploads/2015/08/Beanstream-logo.png" />
# Beanstream PayForm for iOS

##### Table of Contents  

* [Overview](#overview)
* [Platform Support](#platform-support)
* [PayForm](#payform) 
 * [How It Works](#payform-functionality)
 * [Integration Guide](#payform-integration-guide)
* [Building Locally and Contributing](#contributing)

<a name="overview"/>
## Overview

Payform is a Beanstream client-side iOS framework that handles customer credit card input within the merchant's app. This iOS framework limits the scope of a merchant's PCI compliance by removing the need for them to pass the sensitive information (credit card number, CVD, or expiry) through their servers and from having to write and store code that comes in contact with that sensitive information.

By integrating PayForm a developer can easily provide a way for users to accept payments in an iOS app. PayForm provides some client-side validation, smart field data formatting and a design that works in all iOS device form factors.

<a name="platform-support"/>
## iOS Support
 * iOS 8.2+
 * iPhone
 * iPad

<a name="payform"/>
# PayForm

PayForm is a small iOS (Swift) framework project that implemented as a view controller that you can add to your app project. Most apps will let users launch PayForm to gather credit card details from something like a button action.

<a name="payform-functionality"/>
## How It Works
The PayForm controller is instantiated and presented by your app code. The resulting payment form may contain input fields for a shipping address, for a billing address and for credit card details.

Once the user has completed all fields with valid input a processing closure, provided by you, is executed and is passed address information and a token for the credit card details. The processing closure is intended allow the the app developer define a block of code to do any additoinal background processsing and to then dismiss the form.

<a name="payform-integration-guide"/>
## Integration
Adding PayForm to your app could not be easier. You simply use CocoaPods and our Artifactory repository to addat the PayForm framework. PayForm is configured by setting properties on the PayFormViewController instance you create and present. It can be configured to collect shipping and billing addresses in addition to the card details.

The required parameters are:
* amount: the amount you are going to charge the customer
* currency: the currency

The optional parameters are:
* name: your company name
* image: your company logo
* primaryColor: the them color to use - default is #067aed
* purchaseDescription: a description of the purchase
* shippingAddressRequired: if the shipping address is required - true/false
* billingAddressRequired: if the billing address is required - true/false
* processingClosure: the block of code to be executed after a token is received

### Step 1: Setup Dev Tools
The first step is to install CocoaPods on your development machine. Then you will also need to install an Artifactory plugin for CocoaPods. You will then add the needed Beanstream Cocoapods reposotory and add the PayForm Pod to your app project. You can also supply several parameters to configure the form, such as your company name, logo, product description, price, currency, and whether billing/shipping addresses should be displayed. Here is an example:
* Go to https://cocoapods.org on how to setup CocoaPods. This framework was validated with CocoaPods v1.0.1.
* Setup the Artifactory plugin

```bash
> gem install cocoapods-art
```

* Add the Beanstream CocoaPods repo

```bash
> pod repo-art add bic-pods-local "https://beanstream.artifactoryonline.com/beanstream/api/pods/bic-pods-local"
```

* After having executed a 'pod init' in your iOS project directory, add the Artifactory plugin and PayForm pod to your Podfile as follows and then execute the standard 'pod install' command.

```bash
use_frameworks!

plugin 'cocoapods-art', :sources => [
  'bic-pods-local'
]

target 'MyProject' do
  pod 'PayForm'
end
```

* Note that 'pod update' alone does not update Artifactory based pod indexes as expected and use 'pod repo-art update' first and then use 'pod update'.

### Step 1: Add PayForm To Your App
Here is an example, written in Swift of how PayForm is wired to a button action that simply updated a status label.
asdf

```swift
@IBAction func buttonAction(sender: AnyObject) {
    let bundle = NSBundle.init(forClass: PayFormViewController.classForCoder())
    let storyboard = UIStoryboard(name: "PayForm", bundle: bundle)
    if let controller = storyboard.instantiateInitialViewController() as? PayFormViewController {
        self.statusLabel.text = ""
        
        controller.name = "Lollipop Shop"
        controller.amount = NSDecimalNumber(double: 100.00)
        controller.currencyCode = "CAD"
        controller.purchaseDescription = "item, item, item..."
        //controller.primaryColor = UIColor.blueColor()       // default: "#067aed"
        //controller.shippingAddressRequired = true           // default: true
        //controller.billingAddressRequired = true            // default: true
        //controller.tokenRequestTimeoutSeconds = 6           // default: 6
        
        controller.processingClosure = { (result: Dictionary<String, AnyObject>?, error: NSError?) -> Void in
            if let error = error {
                let msg  = "error (\(error.code)): \(error.localizedDescription)"
                self.statusLabel.text = msg
            }
            else if let result = result {
                if let cardInfo = result["cardInfo"] as? Dictionary<String, String>, let token = cardInfo["code"] as String! {
                    self.statusLabel.text = "token: \(token)"
                }
                else {
                    self.statusLabel.text = "No Token!"
                }
                
                if let shippingInfo = result["shippingAddress"] as? Dictionary<String, String> {
                    print("shipping: \(shippingInfo)")
                }
                
                if let billingInfo = result["billingAddress"] as? Dictionary<String, String> {
                    print("billing: \(billingInfo)")
                }
            }
            else {
                let msg = "No error and no result data!"
                self.statusLabel.text = msg
            }
            
            self.dismissViewControllerAnimated(true, completion: nil)
            self.view.setNeedsLayout() // Needed in case of view orientation change
        }
        
        self.presentViewController(controller, animated: true, completion: nil)
    }
}
```

## Step 3: Process The Payment

Whether you collect the tokenized card data and send it asynchronously to your server, or take any other action, you will need to collect the cardInfo code string value that is your token to process the payment with.

Now that you have tokenized card data on your server, use it to either [process or pre-authorize a payment](http://developer.beanstream.com/documentation/take-payments/purchases/take-payment-legato-token/), or create a [payment profile](http://developer.beanstream.com/tokenize-payments/create-new-profile/).

---

<a name="contributing"/>
## Building Locally and Contributing
 * Check out repo: `$ git clone git@github.com:Beanstream/beanstream-ios-payform.git`
 * Open PayFormTest.xcworkspace in Xcode
 * Fork the repo to commit changes to and issue Pull Requests as needed.

---

# API References
* [REST API](http://developer.beanstream.com/documentation/rest-api-reference/)
* [Tokenization](http://developer.beanstream.com/documentation/take-payments/purchases/take-payment-legato-token/)
* [Payment](http://developer.beanstream.com/documentation/take-payments/purchases/card/)
* [Legato](http://developer.beanstream.com/documentation/legato/)
