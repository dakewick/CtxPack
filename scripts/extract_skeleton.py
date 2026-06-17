#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🎯 CtxPack 终极全栈代码骨架提取器 - 工业自动化与上位机深度优化版 (Ultimate Fusion Edition)
兼容：STM32/C/C++/Qt/QML/Python/Linux Shell/配置文件
特性：
1. [防御] 二进制文件智能探测 (\x00 隔离) 与 3MB 超大文件防御。
2. [防御] 全栈垃圾目录深度过滤（OBJ/Listings/Debug/.git/__pycache__等）。
3. [兼容] 编码多重回退机制，GBK 优先级提前，完美兼容国内单片机环境的中文注释。
4. [C语言] 独创纯 C 独立函数与全局外设函数精准抓取，深度匹配 HAL 库/FreeRTOS。
5. [C++] 精准捕获 Class 继承体系、Qt 信号槽发射(emit)及关键非 UI 信号槽连接。
6. [数据] 高效提取配置文件常量（过滤头文件守卫）、QUrl 网络端点及 API 路径。
7. [AI优化] 自动生成 Mermaid 架构图、核心业务流程摘要及 AI 修改热点指南。
8. [📊 Token防御] 内置零依赖代码级 Token 高精估算器，支持全量压缩率矩阵输出。
"""
import os
import sys
import re
from pathlib import Path
from datetime import datetime

# ============================================
# 扫描范围与过滤配置
# ============================================
VALID_EXTENSIONS = ('.h', '.cpp', '.c', '.cc', '.cxx', '.qml', '.sh', '.py', '.conf', '.service', '.ini')
VALID_FILENAMES = ('Makefile', 'CMakeLists.txt', 'Dockerfile', 'requirements.txt')

IGNORE_DIRS = {
    'build', 'release', 'debug', '.git', '.utils', '__pycache__',
    'OBJ', 'Listings', 'Objects', 'Debug', 'Release',
    'Drivers', 'Middlewares', 'CMSIS'
}

SKIP_PATTERNS = [
    r'setSectionResizeMode', r'setFlags\(', r'setAlignment\(', r'setTextAlignment\(',
    r'horizontalHeader\(\)', r'verticalHeader\(\)', r'QTimer::singleShot\(0,',
    r'setStyleSheet\(', r'setFixedSize\(', r'setFixedHeight\(', r'setFixedWidth\(',
    r'painter->', r'QPainter\s', r'p\.draw', r'p\.fill', r'p\.set',
    r'setRenderHint\(', r'fillRect\(', r'drawText\(', r'drawEllipse\(',
    r'QStyledItemDelegate', r'initStyleOption\(', r'QFont\s+\w+;', r'font\.set',
    r'boldFont\.', r'lockIcon\.', r'\.paint\(painter',
    r'\.height\(\)\s*-\s*\w+\)\s*/\s*2', r'setHeight\(', r'adjusted\(',
    r'iconSize', r'margin', r'textRect', r'M_PI\s*=',
]


class ProjectContext:
    def __init__(self):
        self.configs = {}
        self.connections = []
        self.api_endpoints = []
        self.class_hierarchy = {}
        self.business_methods = {}
        self.c_functions = []
        self.total_methods = 0
        self.total_configs = 0

    def categorize_method(self, method_name, code_context):
        combined = f"{method_name} {code_context}".lower()
        categories = {
            '🤖 硬件控制': ['gripper', 'valve', 'pump', 'vibrate', 'weigh', 'home', 'move', 'reset', 'clearerror',
                           'clear_error', 'scale', 'motor', 'servo', 'screw', 'capping', 'dispense', 'transfer',
                           'robot', 'gpio', 'uart', 'i2c', 'spi', 'pwm', 'adc', 'dac', 'tim', 'dma', 'exti'],
            '🔗 网络通信': ['connect', 'disconnect', 'send', 'receive', 'socket', 'http', 'request', 'tcp', 'udp',
                           'network', 'modbus', 'serial', 'heartbeat', 'reconnect', 'lwip', 'ethernet', 'mac', 'phy',
                           'rt_'],
            '💾 数据持久化': ['save', 'write', 'read', 'open', 'close', 'file', 'load', 'json', 'xml', 'csv', 'config',
                             'flash', 'eeprom', 'fatfs', 'sdio', 'import', 'export'],
            '🚀 初始化': ['init', 'setup', 'initialize', 'constructor', 'create', 'hal_init', 'systemclock_config',
                         'mx_', '::mainwindow', '::robotcontroller'],
            '🤖 任务执行': ['execute', 'task', 'step', 'pause', 'stop', 'run', 'process', 'start', 'finish', 'complete',
                           'schedule', 'os_task', 'vtask', 'xtask'],
            '👤 用户管理': ['user', 'login', 'logout', 'password', 'admin', 'permission', 'verify', 'authenticate'],
            '✅ 验证检查': ['validate', 'verify', 'check', 'confirm', 'test', 'isvalid', 'is_', 'can_', 'has_',
                           'should_'],
            '📝 日志状态': ['log', 'status', 'error', 'progress', 'debug', 'print', 'report', 'notify', 'update',
                           'refresh', 'printf'],
        }
        for cat, keywords in categories.items():
            if any(kw in combined for kw in keywords):
                return cat
        return '🔧 功能方法'


context = ProjectContext()


def estimate_tokens(text):
    """
    ⚡ 零依赖工业级源码 Token 估算器
    针对代码文件包含大量特殊符号、缩进及关键字的特征，采用 3.2 字符/Token 的金标准系数进行反序列化预估
    """
    if not text:
        return 0
    return max(1, int(len(text) / 3.2))


def is_ui_detail(code):
    for pattern in SKIP_PATTERNS:
        if re.search(pattern, code):
            return True
    return False


def is_header_guard(name, value):
    return ((name.endswith('_H') or name.endswith('_H_')) and
            ('include' in value.lower() or value.startswith('#') or value == name))


def is_binary_file(file_path):
    try:
        with open(file_path, 'rb') as f:
            chunk = f.read(1024)
            if b'\x00' in chunk:
                return True
    except Exception:
        return True
    return False


def extract_skeleton(file_path):
    file_name = os.path.basename(file_path)
    ext = os.path.splitext(file_name)[1]

    try:
        file_size = os.path.getsize(file_path)
        if file_size > 3 * 1024 * 1024:
            return f"  [⚠️ 跳过超大文件: {file_name} ({file_size / 1024 / 1024:.1f} MB)]", 0, 0, 0, 0
    except Exception:
        return "", 0, 0, 0, 0

    if is_binary_file(file_path):
        return "", 0, 0, 0, 0

    encodings = ['utf-8', 'gbk', 'utf-8-sig', 'latin-1', 'cp1252']
    content = None
    for enc in encodings:
        try:
            with open(file_path, 'r', encoding=enc) as f:
                content = f.read()
            break
        except Exception:
            continue

    if not content:
        return "", 0, 0, 0, 0

    # 📊 累加计算该文件原始全量估算 Token 
    file_raw_tokens = estimate_tokens(content)

    lines = content.split('\n')
    skeleton = []
    file_methods = 0
    file_configs = 0
    file_classes = 0

    try:
        config_patterns = [
            (r'static\s+const\s+(?:char\*|QString|std::string)\s+(\w+)\s*=\s*"([^"]*)"', False),
            (r'static\s+const\s+int\s+(\w+)\s*=\s*(\d+)', False),
            (r'const\s+(?:char\*|QString)\s+(\w+)\s*=\s*"([^"]*)"', False),
            (r'#define\s+(\w+)\s+"?([^"\s]+)"?', False),
            (r'^(\w+)\s*=\s*["\']([^"\']+)["\']', True),
            (r'^(\w+)\s*=\s*(\d+)', True),
        ]

        for pattern, is_python in config_patterns:
            for match in re.finditer(pattern, content, re.MULTILINE):
                name = match.group(1)
                value = match.group(2)
                if not is_python and is_header_guard(name, value): continue
                if is_python and not name.isupper(): continue
                if name not in context.configs:
                    context.configs[name] = value
                    file_configs += 1

        api_matches = re.findall(r'(https?://[^\s"\'\]\)]+)', content)
        for url in api_matches:
            if ('api' in url.lower() or 'localhost' in url or re.search(r'\d+\.\d+\.\d+\.\d+', url)):
                if url not in context.api_endpoints: context.api_endpoints.append(url)

        qurl_matches = re.findall(r'QUrl\("([^"]*)"\)', content)
        for url in qurl_matches:
            if url not in context.api_endpoints: context.api_endpoints.append(url)

        for line in lines:
            clean_line = line.strip()
            if not clean_line or clean_line.startswith(('//', '*', '/*', '--')): continue

            if ext == '.h':
                class_match = re.search(r'class\s+(\w+)\s*(?::\s*(?:public|private|protected)\s+(\w+))?', clean_line)
                if class_match:
                    class_name = class_match.group(1)
                    parent = class_match.group(2)
                    if parent:
                        context.class_hierarchy[class_name] = parent
                        file_classes += 1
                        skeleton.append(f"\n### class {class_name} : public {parent}")
                    else:
                        file_classes += 1
                        skeleton.append(f"\n### class {class_name}")
                elif any(x in clean_line for x in ['Q_OBJECT', 'signals:', 'public slots:', 'private slots:']):
                    skeleton.append(f"  {clean_line}")
                elif '(' in clean_line and clean_line.rstrip().endswith(');'):
                    if not is_ui_detail(clean_line): skeleton.append(f"    {clean_line}")

            elif ext in ('.cpp', '.c', '.cc', '.cxx'):
                method_match = re.search(r'(?:(\w+(?:\s*\*)?)\s+)?(\w+)::(\w+)\s*\(([^)]*)\)\s*(?:const\s*)?{',
                                         clean_line)
                c_func_match = re.search(r'^(?:static\s+)?([\w\s\*]+)\s+(\w+)\s*\(([^)]*)\)\s*(?:{|$)', clean_line)

                if method_match:
                    return_type = method_match.group(1) or 'void'
                    class_name = method_match.group(2)
                    method_name = method_match.group(3)
                    params = method_match.group(4)
                    if not is_ui_detail(clean_line):
                        category = context.categorize_method(method_name, clean_line)
                        signature = f"{return_type} {method_name}({params.strip()})"
                        if class_name not in context.business_methods: context.business_methods[class_name] = {}
                        context.business_methods[class_name][method_name] = {'signature': signature,
                                                                             'category': category}
                        file_methods += 1
                        skeleton.append(f"  {category}: {signature}")

                elif c_func_match and "::" not in clean_line and "return" not in clean_line and "=" not in clean_line:
                    return_type = c_func_match.group(1).strip()
                    method_name = c_func_match.group(2).strip()
                    params = c_func_match.group(3).strip()
                    if return_type not in ('if', 'for', 'while', 'switch') and method_name not in ('if', 'for',
                                                                                                   'while'):
                        if not is_ui_detail(clean_line):
                            category = context.categorize_method(method_name, clean_line)
                            signature = f"{return_type} {method_name}({params})"
                            context.c_functions.append({'signature': signature, 'category': category})
                            file_methods += 1
                            skeleton.append(f"  {category}: {signature}")

                elif 'emit ' in clean_line and not clean_line.startswith('//'):
                    skeleton.append(f"  📡 emit: {clean_line.strip()[:120]}")
                elif 'connect(' in clean_line:
                    conn_match = re.search(r'connect\([^,]+,\s*&(\w+)::(\w+)', clean_line)
                    if conn_match:
                        class_name = conn_match.group(1)
                        signal = conn_match.group(2)
                        ui_signals = {'clicked', 'pressed', 'released', 'valueChanged', 'editingFinished',
                                      'currentChanged', 'itemClicked', 'cellChanged', 'cellDoubleClicked',
                                      'cellClicked', 'timeout', 'triggered', 'accepted', 'rejected'}
                        if signal not in ui_signals and not is_ui_detail(clean_line):
                            context.connections.append(f"{class_name}::{signal}")
                            skeleton.append(f"  📡 {class_name}::{signal} → ...")

            elif ext == '.py':
                if clean_line.startswith('class '):
                    class_match = re.search(r'class\s+(\w+)\s*(?:\(([^)]*)\))?', clean_line)
                    if class_match:
                        name = class_match.group(1)
                        parent = class_match.group(2) or ''
                        context.class_hierarchy[name] = parent
                        file_classes += 1
                        skeleton.append(f"\n### 🐍 class {name}")
                elif clean_line.startswith('def ') or clean_line.startswith('async def '):
                    func_def = clean_line.split(':')[0]
                    method_name = re.search(r'(?:async\s+)?def\s+(\w+)', func_def)
                    if method_name:
                        category = context.categorize_method(method_name.group(1), clean_line)
                        skeleton.append(f"  {category}: {func_def}")
                        file_methods += 1
                elif clean_line.startswith(('import ', 'from ')):
                    skeleton.append(f"  📦 {clean_line[:80]}")
                elif clean_line.startswith('@'):
                    skeleton.append(f"  {clean_line}")

            elif ext == '.sh':
                if clean_line.startswith('function ') or '()' in clean_line:
                    skeleton.append(f"  [Function] {clean_line[:100]}")
                elif clean_line.startswith('export '):
                    skeleton.append(f"  [Env] {clean_line[:100]}")

            elif ext in ('.conf', '.service', '.ini'):
                if '=' in clean_line and not clean_line.startswith(('[', ';', '#')):
                    skeleton.append(f"  {clean_line[:120]}")
        if file_configs > 0:
            for name, value in list(context.configs.items())[-file_configs:]:
                if name not in str(skeleton): skeleton.insert(0, f"  ⚙️ {name} = {value}")

    except Exception as e:
        skeleton.append(f"  [⚠️ 解析异常，已自动保护并跳过此文件剩余部分: {str(e)}]")

    return '\n'.join(skeleton), file_methods, file_configs, file_classes, file_raw_tokens


def generate_summary():
    summary = ["\n## 🏗️ 系统架构\n", "```mermaid\ngraph TB"]
    if context.class_hierarchy:
        for child, parent in list(context.class_hierarchy.items())[:20]:
            if parent: summary.append(f"    {parent} --> {child}")
    if not context.class_hierarchy and context.business_methods:
        classes = list(context.business_methods.keys())[:10]
        for i in range(len(classes) - 1): summary.append(f"    {classes[i]} --> {classes[i + 1]}")
    if not context.class_hierarchy and context.c_functions:
        summary.append("    Subsystem_C_Driver --> Core_Functions")
    summary.append("```\n")

    summary.append("## 🔄 核心业务流程\n")
    if context.business_methods:
        for class_name, methods in list(context.business_methods.items())[:10]:
            important = {k: v for k, v in methods.items() if v['category'] != '🔧 功能方法'}
            if important:
                summary.append(f"\n### {class_name}\n")
                for method_name, info in list(important.items())[:8]:
                    summary.append(f"- `{info['signature']}` - {info['category']}")

    if context.c_functions:
        summary.append("\n### 🔬 核心底驱动/函数 (C 语言)\n")
        important_c = [f for f in context.c_functions if f['category'] != '🔧 功能方法']
        for info in important_c[:15]:
            summary.append(f"- `{info['signature']}` - {info['category']}")

    if not context.business_methods and not context.c_functions:
        summary.append("_无复杂面向对象或独立函数业务流程_\n")

    summary.append("\n## 📊 数据流与关键端点\n")
    if context.configs:
        summary.append("\n### ⚙️ 核心配置常量\n")
        for k, v in list(context.configs.items())[:15]: summary.append(f"- `{k}` = `{v}`")
    if context.api_endpoints:
        summary.append("\n### 🌐 网络/网络通信端点\n")
        for api in context.api_endpoints[:8]: summary.append(f"- `{api}`")
    if context.connections:
        summary.append("\n### 📡 关键跨类信号槽连接\n")
        for conn in context.connections[:10]: summary.append(f"- `{conn}`")

    summary.append("\n## 🎯 AI 逆向工程与开发指南\n")
    summary.append("### 🔍 修改热点引导\n")
    all_classes = ' '.join(context.business_methods.keys())
    all_methods = ' '.join(
        str(v) for methods in context.business_methods.values() for v in methods.values()) + ' '.join(
        f['signature'] for f in context.c_functions)

    if 'mainwindow' in all_classes.lower() or 'widget' in all_classes.lower():
        summary.append("- 🖥️ **GUI上位机交互修改**：优先查阅 MainWindow / Widget 相关 UI 类骨架。")
    if 'controller' in all_classes.lower() or 'socket' in all_classes.lower() or 'modbus' in all_methods.lower():
        summary.append("- 🔗 **通信链路修改**：涉及底层协议或通信重连，检查连接控制类。")
    if any(k in all_methods.lower() for k in ['gripper', 'valve', 'motor', 'servo', 'hal_']):
        summary.append("- 🤖 **底层硬件控制**：涉及运动控制、机械手、气阀动作，优先排查带 `🤖 硬件控制` 标签的方法或 C 函数。")
    if context.configs:
        summary.append("- ⚙️ **全局常量重构**：如需调整端口、下位机 ID、超限阈值，直接搜索带有 `⚙️` 的核心配置项。")

    summary.append("\n### 🚀 开发建议\n")
    if context.class_hierarchy:
        parents = set(v for v in context.class_hierarchy.values() if v)
        if parents: summary.append(
            f"- 项目依赖核心基类：`{', '.join(list(parents)[:6])}`，修改子类时请注意基类虚函数实现。")
    summary.append("- 逆向上下文中已过滤大量纯样式及布局噪点，请开发者在提示 AI 时结合 `🔄 核心业务流程` 进行精准切入。")

    return '\n'.join(summary)


def main():
    target_dir = sys.argv[1] if len(sys.argv) > 1 else os.getcwd()
    output_file = os.path.join(target_dir, 'project_map.md')
    print(f"🚀 [CtxPack 提取器] 启动，目标路径: {target_dir}")

    # 用于在内存中缓存各文件骨架，最后统一写入，方便全局计算生成文件的最终 Token 数
    payload_buffer = []
    file_count, total_methods, total_configs, total_classes, total_lines = 0, 0, 0, 0, 0
    total_raw_tokens = 0

    for root, dirs, files in os.walk(target_dir):
        dirs[:] = [d for d in dirs if d not in IGNORE_DIRS and not d.startswith('.')]
        for file in sorted(files):
            if file.startswith(('moc_', 'qrc_', 'ui_', 'qmlcache_')): continue

            if file.endswith(VALID_EXTENSIONS) or file in VALID_FILENAMES:
                if file == os.path.basename(__file__): continue

                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, target_dir)

                skeleton, methods, configs, classes, raw_tokens = extract_skeleton(file_path)

                if skeleton.strip() or "⚠️" in skeleton:
                    file_count += 1
                    total_methods += methods
                    total_configs += configs
                    total_classes += classes
                    total_raw_tokens += raw_tokens

                    try:
                        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                            total_lines += sum(1 for _ in f)
                    except:
                        pass

                    payload_buffer.append(f"\n## 📄 {rel_path}\n```\n{skeleton}\n```\n")

    # 组装完整的 Markdown 内容
    main_content = "".join(payload_buffer) + generate_summary()

    # 📊 计算 CtxPack 压缩提取后的最终骨架总文本 Token 数
    compressed_tokens = estimate_tokens(main_content)

    # 计算极客级精炼压榨率
    deflation_ratio = 0.0
    if total_raw_tokens > 0:
        deflation_ratio = (1.0 - (compressed_tokens / total_raw_tokens)) * 100.0

    # 统一写入本地物理磁盘
    with open(output_file, 'w', encoding='utf-8') as out:
        out.write("# 📦 CtxPack // 项目架构智能分析地图 (Ultimate Fusion Edition)\n")
        out.write(f"> 🎯 生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        out.write("> 🤖 编译环境: CtxPack Core v1.0 | DEPLOYED BY dakewick\n\n")

        out.write(main_content)

        # ============================================
        # 📊 终极特化：Token 压缩防御效能面板数据沉淀
        # ============================================
        out.write(f"\n## 📈 项目总体指标统计\n")
        out.write(f"- 📁 有效解析工程文件: {file_count} 个 | 📝 估算源码有效总行数: {total_lines:,} 行\n")
        out.write(
            f"- 🔧 捕获业务函数/核心方法: {total_methods} 个 | ⚙️ 核心配置/常量项: {total_configs} 个 | 🏗️ 类定义层级: {total_classes} 个\n")
        out.write(
            f"- 📉 [Token 压缩防御矩阵] 原始全量体积: {total_raw_tokens:,} Tokens ➔ CtxPack 压缩精炼骨架: {compressed_tokens:,} Tokens\n")
        out.write(
            f"- ⚡ [CtxPack 效能评级] 本次架构强力逆向压榨率: {deflation_ratio:.1f}% | AI 上下文视窗安全系数极高\n")

    print(f"✨ 扫描圆满完成！Token 压榨矩阵已锁定。已生成 AI 上下文地图: project_map.md")


if __name__ == '__main__':
    main()