cmake_minimum_required(VERSION 3.14)
project(shirm_crypto)

set(SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../src)
set(SOURCES
    ${SRC_DIR}/shirm_crypto.c
)

add_library(shirm_crypto SHARED ${SOURCES})

set(OPENSSL_ROOT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/openssl_${ANDROID_ABI})
set(ZLIB_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/zlib_${ANDROID_ABI})

find_package(OpenSSL REQUIRED)
find_package(ZLIB REQUIRED)

target_link_libraries(shirm_crypto
    OpenSSL::SSL
    OpenSSL::Crypto
    ZLIB::ZLIB
    log
)

target_compile_definitions(shirm_crypto PRIVATE DART_SHARED_LIB)