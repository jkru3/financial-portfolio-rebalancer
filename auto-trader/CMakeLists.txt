cmake_minimum_required(VERSION 3.15)

# Set vcpkg toolchain file
if(DEFINED ENV{VCPKG_ROOT})
    set(CMAKE_TOOLCHAIN_FILE "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake"
        CACHE STRING "Vcpkg toolchain file")
else()
    message(FATAL_ERROR "Please set VCPKG_ROOT environment variable to your vcpkg installation directory")
endif()

# Set the vcpkg triplet for Apple Silicon
if(APPLE AND CMAKE_SYSTEM_PROCESSOR STREQUAL "arm64")
    set(VCPKG_TARGET_TRIPLET "arm64-osx")
endif()

project(stock_analyzer VERSION 1.0)

# Specify C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g")

# Find and configure packages
find_package(CLI11 CONFIG REQUIRED)
find_package(fmt CONFIG REQUIRED)
find_package(nlohmann_json CONFIG REQUIRED)
find_package(spdlog CONFIG REQUIRED)

# Disable implicit conversions for nlohmann_json
set(nlohmann-json_IMPLICIT_CONVERSIONS OFF)

# Link libraries to the main target
add_executable(stock_analyzer src/main.cpp src/loader.cpp src/portfolio_rebalancer.cpp src/writer.cpp)

# Add this after your add_executable() command
file(COPY ${CMAKE_SOURCE_DIR}/data DESTINATION ${CMAKE_BINARY_DIR})

target_link_libraries(stock_analyzer PRIVATE CLI11::CLI11 fmt::fmt nlohmann_json::nlohmann_json spdlog::spdlog)