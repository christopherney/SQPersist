Pod::Spec.new do |s|
  s.name         = "SQPersist"
  s.version      = "1.0.2"
  s.summary      = "Objective-C Persistence framework wrapper around SQLite."
  s.homepage     = "https://github.com/christopherney/SQPersist"
  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "Christopher Ney" => "christopher.ney@gmail.com" }
  s.social_media_url   = "http://twitter.com/christopherney"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/christopherney/SQPersist.git", :tag => "1.0.2" }
  s.source_files  = "Sources/*.{h,m}"
  # s.exclude_files = "Sources/Exclude"
  s.public_header_files = "Sources/**/*.h"
  s.requires_arc = true
  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  s.dependency "FMDB", "~> 2.4"
end
