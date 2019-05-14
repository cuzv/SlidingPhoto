Pod::Spec.new do |s|
  s.name         = "SlidingPhoto"
  s.version      = "1.3.1"
  s.summary      = "SlidingPhoto is a light weight photo browser, like the wechat, weibo image viewer."

  s.homepage     = "https://github.com/cuzv/SlidingPhoto.git"
  s.license      = "MIT"
  s.author       = { "Shaw" => "cuzval@gmail.com" }
  s.platform     = :ios, "9.0"
  s.requires_arc = true
  s.source       = { :git => "https://github.com/cuzv/SlidingPhoto.git",
:tag => s.version.to_s }
  s.source_files = "Sources/*.{h,swift}"
  s.frameworks   = 'Foundation', 'UIKit'
end
