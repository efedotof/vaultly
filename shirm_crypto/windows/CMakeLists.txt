cmake_minimum_required(VERSION 3.14)
set(PROJECT_NAME "shirm_crypto")
project(${PROJECT_NAME} LANGUAGES C)
add_subdirectory("${CMAKE_CURRENT_SOURCE_DIR}/../src" "${CMAKE_CURRENT_BINARY_DIR}/shared")
set(shirm_crypto_bundled_libraries
    $<TARGET_FILE:shirm_crypto>
    PARENT_SCOPE
)