cmake_minimum_required(VERSION 3.16)

project(AIAgent_ContextCompressor VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ✅ 补充解耦必需的组件模块
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Network)

qt_standard_project_setup(REQUIRES 6.10)

# =========================================================
# ⚙️ Windows 平台专属配置：锁定图标脚本，直接熔铸入二进制文件
# =========================================================
set(WINDOWS_ICON_RESOURCE "")
if(WIN32)
    # 💡 此时 app.rc 和 favicon.ico 应完好地躺在当前 CMakeLists.txt 的同级目录下
    set(WINDOWS_ICON_RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/app.rc")
endif()

qt_add_executable(appAIAgent_ContextCompressor
    main.cpp
    ${WINDOWS_ICON_RESOURCE} # 👈 1. 注入到目标可执行文件中
)

qt_add_qml_module(appAIAgent_ContextCompressor
    URI AIAgent_ContextCompressor
    VERSION 1.0
    QML_FILES
        Main.qml
        ChatWindow.qml
    SOURCES
        compressorbackend.h
        compressorbackend.cpp
        chatbackend.h
        chatbackend.cpp
        ${WINDOWS_ICON_RESOURCE} # 👈 2. 注入到 QML 编译模块的源码树中
)

# =========================================================
# 🎯 核心修复：实施跨平台属性隔离，彻底封杀 appman 错误
# =========================================================
if(APPLE)
    set_target_properties(appAIAgent_ContextCompressor PROPERTIES
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        MACOSX_BUNDLE TRUE
    )
elseif(WIN32)
    set_target_properties(appAIAgent_ContextCompressor PROPERTIES
        WIN32_EXECUTABLE TRUE # 👈 确保 Windows 下运行时不弹黑色 CMD 终端，但绝不碰 MACOSX_BUNDLE
    )
endif()

# ✅ 链接所有必需的 Qt6 模块
target_link_libraries(appAIAgent_ContextCompressor
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Network
)

install(TARGETS appAIAgent_ContextCompressor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# 🚀 构建后自动复制资源到可执行文件同级目录
add_custom_command(TARGET appAIAgent_ContextCompressor POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/extract_skeleton.py"
        "${CMAKE_CURRENT_BINARY_DIR}/"
)