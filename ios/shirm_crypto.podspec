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

  s.dependency 'Flutter'
  s.platform = :ios, '13.0'

  s.ios.vendored_libraries = 'openssl_prebuild_device/15.0/libssl.a', 
                             'openssl_prebuild_device/15.0/libcrypto.a'
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386',
    'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/openssl_prebuild_device/15.0/include',
    'OTHER_LDFLAGS' => '-lz'  
  }
  s.swift_version = '5.0'
end