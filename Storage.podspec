Pod::Spec.new do |spec|
  spec.name         = "Storage"
  spec.version      = "1.0.0"
  spec.summary      = "A simple Storage library based on SQLite"
  spec.homepage     = "https://github.com/couchbits/Storage"
  spec.license         = { :type => 'MIT' }
  spec.author       = { "Dominik Gauggel" => "dominik@couchbits.com" }
  spec.platform     = :ios, "9.0"
  spec.source       = { :git => "https://github.com/couchbits/Storage.git", :tag => "#{spec.version}" }

  spec.source_files  = "Storage", "Storage/**/*.{h,m,swift}"
  spec.exclude_files = "Storage/Exclude"
end
