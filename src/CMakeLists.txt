cmake_minimum_required(VERSION 3.10)

project(shirm_crypto_library VERSION 0.0.1 LANGUAGES C)

add_library(shirm_crypto SHARED
  "shirm_crypto.c"
)

set_target_properties(shirm_crypto PROPERTIES
  PUBLIC_HEADER shirm_crypto.h
  OUTPUT_NAME "shirm_crypto"
)

target_compile_definitions(shirm_crypto PUBLIC DART_SHARED_LIB)

find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)
target_link_libraries(shirm_crypto PRIVATE OpenSSL::SSL OpenSSL::Crypto ZLIB::ZLIB)

if (ANDROID)
  target_link_options(shirm_crypto PRIVATE "-Wl,-z,max-page-size=16384")
endif()