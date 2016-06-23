
Pod::Spec.new do |spec|

  spec.name     = 'PayForm'
  spec.version  = '0.1.3'
  spec.license  = { :type => "MIT", :file => "LICENSE" }
  spec.summary  = 'A delightful Payments UI framework to be helpful with Beanstream related development.'
  spec.homepage = 'http://developer.beanstream.com'
  spec.authors  = 'Sven M. Resch'
  spec.source   = { :git => 'https://github.com/Beanstream/beanstream-ios-payform.git',
  					:tag => spec.version.to_s, :submodules => true }
  spec.requires_arc = true
  spec.ios.deployment_target = '8.2'

  spec.framework        = 'Foundation, UIKit'
  spec.source_files     = 'PayForm/**/*.{swift}'
  spec.resource_bundles = { 'PayForm' => ['PayForm/**/*'] }

end

