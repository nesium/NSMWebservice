Pod::Spec.new do |spec|
  spec.name                 = "NSMWebservice"
  spec.version              = "3.16.0"
  spec.summary              = "SVG"
  spec.homepage             = "https://github.com/nesium/NSMWebservice.git"
  spec.license              = { :type => "MIT" }
  spec.author               = "Marc Bauer"
  spec.platform             = :ios, "10.0"
  spec.source               = { :git => "https://github.com/nesium/NSMWebservice.git", :tag => "#{spec.version}" }
  spec.source_files         = "Sources/**/*.{swift,h}"
  spec.public_header_files  = "Sources/NSMWebservice.h"
  spec.swift_version        = "5.1"
  
  spec.dependency 'RxSwift', '~> 5'
end