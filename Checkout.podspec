
Pod::Spec.new do |spec|

  spec.name     = 'Checkout'
  spec.version  = '0.4.0'
  spec.license  = { :type => "MIT", :file => "LICENSE" }
  spec.summary  = 'A delightful Payments UI framework to be helpful with Bambora related development.'
  spec.homepage = 'http://developer.na.bambora.com'
  spec.authors  = 'Sven M. Resch'
  spec.source   = { :git => 'https://github.com/Bambora/na-ios-checkout.git',
  					:tag => spec.version.to_s, :submodules => true }
  spec.requires_arc = true
  spec.ios.deployment_target = '8.2'

  spec.framework        = 'Foundation, UIKit'
  spec.source_files     = 'Checkout/**/*.{swift}'
  spec.resources = 'Checkout/Resources/**/*'

end

