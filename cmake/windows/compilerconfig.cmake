# CMake Windows compiler configuration module

include_guard(GLOBAL)

include(compiler_common)

# CMake 3.24 introduces a bug mistakenly interpreting MSVC as supporting the '-pthread' compiler flag
if(CMAKE_VERSION VERSION_EQUAL 3.24.0)
  set(THREADS_HAVE_PTHREAD_ARG FALSE)
endif()

# CMake 3.25 changed the way symbol generation is handled on Windows
if(CMAKE_VERSION VERSION_GREATER_EQUAL 3.25.0)
  if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT ProgramDatabase)
  else()
    set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT Embedded)
  endif()
endif()

message(DEBUG "Current Windows API version: ${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION}")
if(CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION_MAXIMUM)
  message(DEBUG "Maximum Windows API version: ${CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION_MAXIMUM}")
endif()

if(CMAKE_C_COMPILER_ID STREQUAL "MSVC")
  if(CMAKE_VS_WINDOWS_TARGET_PLATFORM_VERSION VERSION_LESS 10.0.20348)
    message(FATAL_ERROR "OBS requires Windows 10 SDK version 10.0.20348.0 or more recent.\n"
                        "Please download and install the most recent Windows platform SDK.")
  endif()
endif()

add_compile_options(
  $<$<NOT:$<COMPILE_LANGUAGE:Swift>>:/W3>
  $<$<NOT:$<COMPILE_LANGUAGE:Swift>>:/utf-8>
  "$<$<COMPILE_LANG_AND_ID:C,MSVC>:/MP>"
  "$<$<COMPILE_LANG_AND_ID:CXX,MSVC>:/MP>"
  "$<$<COMPILE_LANG_AND_ID:C,Clang>:${_obs_clang_c_options}>"
  "$<$<COMPILE_LANG_AND_ID:CXX,Clang>:${_obs_clang_cxx_options}>"
  $<$<AND:$<NOT:$<CONFIG:Debug>>,$<NOT:$<COMPILE_LANGUAGE:Swift>>>:/Gy>)

set(CMAKE_Swift_FLAGS "${CMAKE_Swift_FLAGS} -Xcc -DUNICODE -Xcc -D_UNICODE -Xcc -D_CRT_SECURE_NO_WARNINGS -Xcc -D_CRT_NONSTDC_NO_WARNINGS")
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CMAKE_Swift_FLAGS "${CMAKE_Swift_FLAGS} -Xcc -DDEBUG -Xcc -D_DEBUG")
endif()

set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DUNICODE -D_UNICODE -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -DUNICODE -D_UNICODE -D_CRT_SECURE_NO_WARNINGS -D_CRT_NONSTDC_NO_WARNINGS")
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
  set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DDEBUG -D_DEBUG")
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DDEBUG -D_DEBUG")
endif()

message("CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")
message("CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")
message("CMAKE_Swift_FLAGS: ${CMAKE_Swift_FLAGS}")

# cmake-format: off
add_link_options(
  $<$<AND:$<NOT:$<CONFIG:Debug>>,$<NOT:$<COMPILE_LANGUAGE:Swift>>>:/OPT:REF>
  $<$<AND:$<NOT:$<CONFIG:Debug>>,$<NOT:$<COMPILE_LANGUAGE:Swift>>>:/OPT:ICF>
  $<$<AND:$<NOT:$<CONFIG:Debug>>,$<NOT:$<COMPILE_LANGUAGE:Swift>>>:/INCREMENTAL:NO>
  $<$<NOT:$<COMPILE_LANGUAGE:Swift>>:/DEBUG>
  $<$<NOT:$<COMPILE_LANGUAGE:Swift>>:/Brepro>
)
# cmake-format: on

if(CMAKE_COMPILE_WARNING_AS_ERROR)
  add_link_options($<$<NOT:$<COMPILE_LANGUAGE:Swift>>:/WX>)
endif()
