Pod::Spec.new do |s|
  s.name             = 'shirm_crypto'
  s.version          = '0.0.1'
  s.summary          = 'SHIRMPS encryption native library'
  s.description      = <<-DESC
A Flutter FFI plugin for encryption using OpenSSL.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }

  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{c,h,swift}'
  s.public_header_files = 'Classes/**/*.h'

  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/openssl_prebuild/macos-arm/13.0/include ${PODS_TARGET_SRCROOT}/openssl_prebuild/macos-intel/12.0/include'
  }
  s.swift_version = '5.0'
end