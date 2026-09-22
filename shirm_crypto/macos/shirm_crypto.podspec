Pod::Spec.new do |s|
  s.name             = 'shirm_crypto'
  s.version          = '0.0.1'
  s.summary          = 'SHIRMPS encryption native library'
  s.description      = 'A Flutter FFI plugin for encryption using OpenSSL.'
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.{c,h,swift}'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'FlutterMacOS'
  s.platform = :osx, '10.11'

  archs = ENV['FLUTTER_XCODE_ARCHS']&.split || []
  if archs.include?('arm64')
    s.vendored_libraries = 'openssl_prebuild/macos-arm/13.0/libssl.a', 'openssl_prebuild/macos-arm/13.0/libcrypto.a'
    s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/openssl_prebuild/macos-arm/13.0/include' }
  elsif archs.include?('x86_64')
    s.vendored_libraries = 'openssl_prebuild/macos-intel/12.0/libssl.a', 'openssl_prebuild/macos-intel/12.0/libcrypto.a'
    s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/openssl_prebuild/macos-intel/12.0/include' }
  else
    s.vendored_libraries = 'openssl_prebuild/macos-arm/13.0/libssl.a', 'openssl_prebuild/macos-arm/13.0/libcrypto.a'
    s.pod_target_xcconfig = { 'HEADER_SEARCH_PATHS' => '$(inherited) ${PODS_TARGET_SRCROOT}/openssl_prebuild/macos-arm/13.0/include' }
  end
  s.swift_version = '5.0'
end