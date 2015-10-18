
Pod::Spec.new do |s|

  s.name         = 'PromiseSignals'
  s.version      = '0.1.0'
  s.homepage     = 'https://github.com/konoma/promise-signals-ios'
  s.summary      = 'Extends PromiseKit with Signals that can resolve multiple times.'
  s.description  = 'Extends PromiseKit with Signals that can resolve multiple times. Based on PromiseKit.'

  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { 'Markus Gasser' => 'markus.gasser@konoma.ch' }
  
  s.source       = { :git => 'https://github.com/konoma/promise-signals-ios.git', :tag => '0.1.0' }
  s.platform     = :ios, '8.0'
  
  s.requires_arc = true
  s.frameworks   = 'Foundation'

  s.source_files = 'Sources/**/*.{h,m,mm,swift}'

  s.dependency     'PromiseKit/CorePromise', '~> 3.0'
end

