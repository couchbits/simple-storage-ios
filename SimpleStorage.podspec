Pod::Spec.new do |spec|
  spec.name           = "SimpleStorage"
  spec.version        = "1.2.0"
  spec.summary        = "A simple Storage library based on SQLite"
  spec.homepage       = "https://github.com/couchbits/simple-storage-ios"
  spec.license        = { :type => 'MIT' }
  spec.author         = { "Dominik Gauggel" => "dominik@couchbits.com" }
  spec.platform       = :ios, "9.0"
  spec.swift_version  = "5.1"
  spec.source         = { :git => "https://github.com/couchbits/simple-storage-ios.git", :tag => "#{spec.version}" }

  spec.source_files   = "SimpleStorage", "SimpleStorage/**/*.{h,m,swift}"
  spec.exclude_files  = "SimpleStorage/Exclude"
end
