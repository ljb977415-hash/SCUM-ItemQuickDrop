cmake_minimum_required(VERSION 3.22)
project(ItemQuickDrop CXX)

# ============================================================
#  配置区 —— 按你的实际路径修改
# ============================================================
# UE4SS 源码根目录（就是你 git clone RE-UE4SS 的那个文件夹）
# 例子：D:/dev/RE-UE4SS
set(UE4SS_ROOT "${CMAKE_SOURCE_DIR}/../../../RE-UE4SS" CACHE PATH "UE4SS source root")

# 编译输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")

# C++ 标准
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================================
#  找 UE4SS 头文件和库
# ============================================================
# UE4SS 头文件路径
set(UE4SS_INCLUDE_DIR "${UE4SS_ROOT}/include")
set(UE4SS_DEPENDENCIES_DIR "${UE4SS_ROOT}/dependencies")

# UE4SS 预编译库路径（Release 版）
set(UE4SS_LIB_DIR "${UE4SS_ROOT}/lib")

# 检查路径是否存在
if(NOT EXISTS "${UE4SS_INCLUDE_DIR}")
    message(FATAL_ERROR "UE4SS include 目录不存在: ${UE4SS_INCLUDE_DIR}\n请修改 CMakeLists.txt 里的 UE4SS_ROOT 路径")
endif()

# ============================================================
#  项目
# ============================================================
add_library(${PROJECT_NAME} SHARED
    src/main.cpp
)

target_include_directories(${PROJECT_NAME} PRIVATE
    ${UE4SS_INCLUDE_DIR}
    ${UE4SS_DEPENDENCIES_DIR}
    ${UE4SS_DEPENDENCIES_DIR}/Unreal
)

# 链接 UE4SS 库
find_library(UE4SS_LIB 
    NAMES UE4SS
    PATHS ${UE4SS_LIB_DIR}
    NO_DEFAULT_PATH
)

if(UE4SS_LIB)
    target_link_libraries(${PROJECT_NAME} PRIVATE ${UE4SS_LIB})
else()
    message(WARNING "UE4SS.lib 没找到，只编译不链接可能会报错")
endif()

# Windows 下需要的宏
target_compile_definitions(${PROJECT_NAME} PRIVATE
    UNIX
    __UE4SS_OPEN_IS_UOBJECT
)

# 输出 dll 改名 main.dll（UE4SS 约定）
set_target_properties(${PROJECT_NAME} PROPERTIES
    OUTPUT_NAME "main"
    PREFIX ""
    SUFFIX ".dll"
)
