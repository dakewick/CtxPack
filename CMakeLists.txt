cmake_minimum_required(VERSION 3.16)

# 1. 项目定义
project(AIAgent_ContextCompressor VERSION 1.2.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# 2. 引入 Qt6 核心模块
find_package(Qt6 REQUIRED COMPONENTS Quick QuickControls2 Network)

# 3. 初始化 Qt 标准环境 (必须在 add_executable 之前)
qt_standard_project_setup(REQUIRES 6.10)

# 4. 资源文件配置
set(WINDOWS_ICON_RESOURCE "")
if(WIN32)
    set(WINDOWS_ICON_RESOURCE "${CMAKE_CURRENT_SOURCE_DIR}/app.rc")
endif()

# 5. 定义可执行文件 (仅定义一次)
qt_add_executable(appAIAgent_ContextCompressor
    main.cpp
    ${WINDOWS_ICON_RESOURCE}
)

# 6. 配置输出名为 CtxPack
set_target_properties(appAIAgent_ContextCompressor PROPERTIES
    OUTPUT_NAME "CtxPack"
    WIN32_EXECUTABLE TRUE
)

# 7. QML 模块配置
qt_add_qml_module(appAIAgent_ContextCompressor
    URI AIAgent_ContextCompressor
    VERSION 1.0
    QML_FILES
        Main.qml
        ChatWindow.qml
        PromptGenerator.qml
        EmbeddedPromptGenerator.qml
        LinuxPromptGenerator.qml
        GitPanel.qml
    SOURCES
        compressorbackend.h
        compressorbackend.cpp
        chatbackend.h
        chatbackend.cpp
        gitbackend.h
        gitbackend.cpp
        ${WINDOWS_ICON_RESOURCE}
)

# 8. 注入版本宏到 C++ 代码
target_compile_definitions(appAIAgent_ContextCompressor PRIVATE
    APP_NAME="${PROJECT_NAME}"
    APP_VERSION="${PROJECT_VERSION}"
)

# 9. 链接库
target_link_libraries(appAIAgent_ContextCompressor
    PRIVATE
        Qt6::Quick
        Qt6::QuickControls2
        Qt6::Network
)

# 10. 构建后操作 —— 复制 Python 脚本到输出目录
add_custom_command(TARGET appAIAgent_ContextCompressor POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/extract_skeleton.py"
        "$<TARGET_FILE_DIR:appAIAgent_ContextCompressor>/"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "${CMAKE_CURRENT_SOURCE_DIR}/code_radar.py"
        "$<TARGET_FILE_DIR:appAIAgent_ContextCompressor>/"
)

install(TARGETS appAIAgent_ContextCompressor
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)