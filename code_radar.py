import os
import sys
import json
import re

EXCLUDE_DIRS = {'.git', '.svn', 'build', 'out', 'bin', 'debug', 'release', '.vscode', '.idea', 'node_modules'}
VALID_EXTENSIONS = {'.cpp', '.h', '.c', '.hpp', '.qml', '.py'}


def clean_line_for_braces(line):
    line = re.sub(r'".*?(?<!\\)"', '""', line)
    line = re.sub(r"'.*?(?<!\\)'", "''", line)
    line = re.sub(r'//.*', '', line)
    return line


def get_indent_level(line):
    """计算 Python 行的缩进空格数"""
    return len(line) - len(line.lstrip())


def extract_py_block(lines, start_idx):
    """【新算法】专为 Python 打造的缩进闭合提取器"""
    content = [lines[start_idx]]
    base_indent = get_indent_level(lines[start_idx])

    # 向下扫描，直到遇到缩进小于或等于基准缩进的非空非注释行
    for i in range(start_idx + 1, len(lines)):
        line = lines[i]
        stripped = line.strip()

        # 忽略空行和注释行，它们不代表作用域结束
        if not stripped or stripped.startswith('#'):
            content.append(line)
            continue

        current_indent = get_indent_level(line)
        if current_indent <= base_indent:
            break

        content.append(line)

    return "".join(content)


def extract_cpp_block(lines, start_idx):
    """【原算法】专为 C++ / QML 打造的花括号提取器"""
    content = []
    open_braces = 0
    started = False

    # 动态向上抓取 5 行上下文
    context_start = start_idx
    for i in range(start_idx - 1, max(-1, start_idx - 6), -1):
        prev_line = lines[i].strip()
        if not prev_line or prev_line.endswith(';') or prev_line.endswith('}'):
            break
        context_start = i

    for i in range(context_start, start_idx):
        content.append(lines[i])

    for i in range(start_idx, len(lines)):
        raw_line = lines[i]
        content.append(raw_line)

        clean_line = clean_line_for_braces(raw_line)
        open_braces += clean_line.count('{')
        open_braces -= clean_line.count('}')

        if '{' in clean_line:
            started = True

        if started and open_braces <= 0:
            break

        if not started and i > start_idx + 25:
            break

    return "".join(content)


def read_file_safely(filepath):
    for enc in ['utf-8', 'gbk', 'latin-1']:
        try:
            with open(filepath, 'r', encoding=enc) as f:
                return f.readlines()
        except UnicodeDecodeError:
            continue
    return None


def build_search_regex(target_string):
    target_string = target_string.strip()
    if ' ' in target_string:
        parts = target_string.split()
        return_type = parts[0]
        func_name = parts[-1]
        pattern = re.compile(rf"{re.escape(return_type)}\s+(?:\w+::)?{re.escape(func_name)}")
        return pattern
    else:
        return re.compile(re.escape(target_string))


def scan_project(directory, target_string):
    results = []
    regex_pattern = build_search_regex(target_string)

    for root, dirs, files in os.walk(directory):
        dirs[:] = [d for d in dirs if d not in EXCLUDE_DIRS]

        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext in VALID_EXTENSIONS:
                filepath = os.path.join(root, file)
                lines = read_file_safely(filepath)

                if not lines:
                    continue

                for i, line in enumerate(lines):
                    if regex_pattern.search(line):
                        # 💡 根据文件后缀动态分流核心算法
                        if ext == '.py':
                            snippet = extract_py_block(lines, i)
                        else:
                            snippet = extract_cpp_block(lines, i)

                        results.append({
                            "file": os.path.relpath(filepath, directory).replace('\\', '/'),
                            "line": i + 1,
                            "code": snippet.strip()
                        })
                        break

    return results


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(json.dumps({"status": "error", "message": "Usage: python code_radar.py <directory> <target>"}))
        sys.exit(1)

    project_dir = sys.argv[1]
    target_str = sys.argv[2]

    if not os.path.isdir(project_dir):
        print(json.dumps({"status": "error", "message": f"Invalid directory: {project_dir}"}))
        sys.exit(1)

    extracted_data = scan_project(project_dir, target_str)

    response = {
        "status": "success",
        "target": target_str,
        "count": len(extracted_data),
        "results": extracted_data
    }

    print(json.dumps(response, ensure_ascii=False, indent=2))