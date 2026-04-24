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
    if(CMAKE_OSX_ARCHITECTURES MATCHES "arm64")
        set(MACOS_PREBUILD_ARM ${CMAKE_CURRENT_SOURCE_DIR}/../macos/openssl_prebuild/macos-arm/13.0)
        add_library(ssl_arm STATIC IMPORTED)
        set_target_properties(ssl_arm PROPERTIES IMPORTED_LOCATION ${MACOS_PREBUILD_ARM}/libssl.a)
        add_library(crypto_arm STATIC IMPORTED)
        set_target_properties(crypto_arm PROPERTIES IMPORTED_LOCATION ${MACOS_PREBUILD_ARM}/libcrypto.a)
        target_include_directories(shirm_crypto PRIVATE ${MACOS_PREBUILD_ARM}/include)
    endif()

    if(CMAKE_OSX_ARCHITECTURES MATCHES "x86_64")
        set(MACOS_PREBUILD_INTEL ${CMAKE_CURRENT_SOURCE_DIR}/../macos/openssl_prebuild/macos-intel/12.0)
        add_library(ssl_intel STATIC IMPORTED)
        set_target_properties(ssl_intel PROPERTIES IMPORTED_LOCATION ${MACOS_PREBUILD_INTEL}/libssl.a)
        add_library(crypto_intel STATIC IMPORTED)
        set_target_properties(crypto_intel PROPERTIES IMPORTED_LOCATION ${MACOS_PREBUILD_INTEL}/libcrypto.a)
        target_include_directories(shirm_crypto PRIVATE ${MACOS_PREBUILD_INTEL}/include)
    endif()

    if(NOT CMAKE_OSX_ARCHITECTURES)
        set(MACOS_PREBUILD_ARM ${CMAKE_CURRENT_SOURCE_DIR}/../macos/openssl_prebuild/macos-arm/13.0)
        add_library(ssl_arm STATIC IMPORTED)
        set_target_properties(ssl_arm PROPERTIES IMPORTED_LOCATION ${MACOS_PREBUILD_ARM}/libssl.a)
        add_library(crypto_arm STATIC IMPORTED)
        set_target_properties(crypto_arm PROPERTIES IMPORTED_LOCATION ${MACOS_PREBUILD_ARM}/libcrypto.a)
        target_include_directories(shirm_crypto PRIVATE ${MACOS_PREBUILD_ARM}/include)
    endif()

    find_library(SECURITY Security REQUIRED)

    if(TARGET ssl_arm AND TARGET crypto_arm)
        target_link_libraries(shirm_crypto PRIVATE ssl_arm crypto_arm zlib ${SECURITY})
    endif()
    if(TARGET ssl_intel AND TARGET crypto_intel)
        target_link_libraries(shirm_crypto PRIVATE ssl_intel crypto_intel zlib ${SECURITY})
    endif()

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
    set(WIN_PREBUILD ${CMAKE_CURRENT_SOURCE_DIR}/../windows/openssl_prebuild/windows/x86_64)
    target_include_directories(shirm_crypto PRIVATE ${WIN_PREBUILD}/../include)
    add_library(ssl STATIC IMPORTED)
    set_target_properties(ssl PROPERTIES IMPORTED_LOCATION ${WIN_PREBUILD}/libssl.a)
    add_library(crypto STATIC IMPORTED)
    set_target_properties(crypto PROPERTIES IMPORTED_LOCATION ${WIN_PREBUILD}/libcrypto.a)
    target_link_libraries(shirm_crypto PRIVATE ssl crypto zlib)
endif()