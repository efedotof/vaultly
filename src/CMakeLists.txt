cmake_minimum_required(VERSION 3.14)
project(shirm_crypto_library VERSION 0.0.1 LANGUAGES C)

include(FetchContent)

FetchContent_Declare(
    zlib
    URL https://github.com/madler/zlib/archive/refs/tags/v1.3.2.tar.gz
)
FetchContent_MakeAvailable(zlib)

add_library(shirm_crypto SHARED
    "shirm_crypto.c"
    "sqlite/sqlite3.c"
)

set_target_properties(shirm_crypto PROPERTIES
    PUBLIC_HEADER shirm_crypto.h
    OUTPUT_NAME "shirm_crypto"
)

target_compile_definitions(shirm_crypto PUBLIC DART_SHARED_LIB)

target_include_directories(shirm_crypto PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/sqlite
)

if(ANDROID)
    add_library(ssl SHARED IMPORTED)
    set_target_properties(ssl PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/libssl.so)

    add_library(crypto SHARED IMPORTED)
    set_target_properties(crypto PROPERTIES
        IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/libcrypto.so)

    target_include_directories(shirm_crypto PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/../android/src/main/jniLibs/${ANDROID_ABI}/include)

    target_link_libraries(shirm_crypto PRIVATE ssl crypto zlib log)
    target_link_options(shirm_crypto PRIVATE "-Wl,-z,max-page-size=16384")

elseif(APPLE AND NOT IOS)
    if(DEFINED ENV{OPENSSL_PREBUILD_DIR})
        set(OPENSSL_DIR $ENV{OPENSSL_PREBUILD_DIR})
    elseif(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
        set(OPENSSL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../macos/openssl_prebuild/macos-arm/13.0)
    elseif(CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
        set(OPENSSL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../macos/openssl_prebuild/macos-intel/12.0)
    else()
        set(OPENSSL_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../macos/openssl_prebuild/macos-arm/13.0)
    endif()

    add_library(ssl STATIC IMPORTED)
    set_target_properties(ssl PROPERTIES IMPORTED_LOCATION ${OPENSSL_DIR}/libssl.a)
    add_library(crypto STATIC IMPORTED)
    set_target_properties(crypto PROPERTIES IMPORTED_LOCATION ${OPENSSL_DIR}/libcrypto.a)
    target_include_directories(shirm_crypto PRIVATE ${OPENSSL_DIR}/include)
    find_library(SECURITY Security REQUIRED)
    target_link_libraries(shirm_crypto PRIVATE ssl crypto zlib ${SECURITY})

elseif(IOS)
    if(CMAKE_SYSROOT MATCHES "iphonesimulator")
        set(IOS_PREBUILD ${CMAKE_CURRENT_SOURCE_DIR}/../ios/openssl_prebuild_simulator/15.0)
    else()
        set(IOS_PREBUILD ${CMAKE_CURRENT_SOURCE_DIR}/../ios/openssl_prebuild_device/15.0)
    endif()
    add_library(ssl STATIC IMPORTED)
    set_target_properties(ssl PROPERTIES IMPORTED_LOCATION ${IOS_PREBUILD}/libssl.a)
    add_library(crypto STATIC IMPORTED)
    set_target_properties(crypto PROPERTIES IMPORTED_LOCATION ${IOS_PREBUILD}/libcrypto.a)
    target_include_directories(shirm_crypto PRIVATE ${IOS_PREBUILD}/include)
    target_link_libraries(shirm_crypto PRIVATE ssl crypto zlib)

elseif(UNIX AND NOT APPLE)
    set(LINUX_PREBUILD ${CMAKE_CURRENT_SOURCE_DIR}/../linux/openssl_prebuild/x86_64)
    add_library(ssl STATIC IMPORTED)
    set_target_properties(ssl PROPERTIES IMPORTED_LOCATION ${LINUX_PREBUILD}/libssl.a)
    add_library(crypto STATIC IMPORTED)
    set_target_properties(crypto PROPERTIES IMPORTED_LOCATION ${LINUX_PREBUILD}/libcrypto.a)
    target_include_directories(shirm_crypto PRIVATE ${LINUX_PREBUILD}/include)
    target_link_libraries(shirm_crypto PRIVATE ssl crypto zlib)

elseif(WIN32)
    set(WIN_INCLUDE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../windows/openssl_prebuild/windows/include)
    set(WIN_LIB_DIR ${CMAKE_CURRENT_SOURCE_DIR}/../windows/openssl_prebuild/windows/x86_64)
    target_include_directories(shirm_crypto PRIVATE
        ${WIN_INCLUDE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/win32
    )
    add_library(ssl STATIC IMPORTED)
    set_target_properties(ssl PROPERTIES IMPORTED_LOCATION ${WIN_LIB_DIR}/libssl.lib)
    add_library(crypto STATIC IMPORTED)
    set_target_properties(crypto PROPERTIES IMPORTED_LOCATION ${WIN_LIB_DIR}/libcrypto.lib)
    target_link_libraries(shirm_crypto PRIVATE ssl crypto zlib ws2_32 crypt32 secur32 advapi32 user32)
endif()