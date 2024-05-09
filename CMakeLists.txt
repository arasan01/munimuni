cmake_minimum_required(VERSION 3.16...3.29)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

project(${_name}
  VERSION ${_version}
  LANGUAGES C CXX Swift
)

# Workaround for .deps\include/media-io/../util/util_uint64.h(29,9):
# error: use of undeclared identifier '_udiv128
add_compile_options(
  $<$<NOT:$<COMPILE_LANGUAGE:Swift>>:-fmsc-version=1919>
)

option(ENABLE_FRONTEND_API "Use obs-frontend-api for UI functionality" OFF)
option(ENABLE_QT "Use Qt functionality" OFF)

include(compilerconfig)
include(defaults)
include(helpers)
include(AddSwift)

set(PROJECT_BRIDGE_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/include")
include_directories(${PROJECT_BRIDGE_INCLUDE_DIR})

add_library(${CMAKE_PROJECT_NAME} MODULE)

find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

if(ENABLE_FRONTEND_API)
  find_package(obs-frontend-api REQUIRED)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)
endif()

if(ENABLE_QT)
  find_package(Qt6 COMPONENTS Widgets Core)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Core Qt6::Widgets)
  target_compile_options(
    ${CMAKE_PROJECT_NAME} PRIVATE $<$<NOT:$<COMPILE_LANGUAGE:Swift>>:
      $<$<C_COMPILER_ID:Clang,AppleClang>:-Wno-quoted-include-in-framework-header -Wno-comma>
    >)
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES AUTOMOC ON
               AUTOUIC ON
               AUTORCC ON)
endif()

set_target_properties(${CMAKE_PROJECT_NAME} PROPERTIES Swift_MODULE_NAME "${CMAKE_PROJECT_NAME}")
target_compile_options(${CMAKE_PROJECT_NAME} PUBLIC
  $<$<COMPILE_LANGUAGE:Swift>:-cxx-interoperability-mode=default>)
target_compile_options(${CMAKE_PROJECT_NAME} PUBLIC
  $<$<COMPILE_LANGUAGE:Swift>:-swift-version 6>)
target_compile_options(${CMAKE_PROJECT_NAME}
  PRIVATE $<$<COMPILE_LANGUAGE:Swift>:-index-store-path ${CMAKE_BINARY_DIR}/IndexStore/index>
)
target_compile_options(${CMAKE_PROJECT_NAME} PRIVATE $<$<COMPILE_LANGUAGE:Swift>:-Xcc> $<$<COMPILE_LANGUAGE:Swift>:-std=c++17>)
_swift_generate_cxx_header(${CMAKE_PROJECT_NAME}
  ${CMAKE_PROJECT_NAME}/${CMAKE_PROJECT_NAME}-swift.h
  SEARCH_PATHS "${PROJECT_BRIDGE_INCLUDE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/.deps/include")

target_sources(
  ${CMAKE_PROJECT_NAME}
  PRIVATE # cmake-format: sortable
    src/plugin-main.cpp
    src/swift-hepler.cpp
    src/ColorSources.swift
    src/BridgeHelper.swift
    src/Extensions/OBSSourceInfo+Extension.swift
)

set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${_name})
