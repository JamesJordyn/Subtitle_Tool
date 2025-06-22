#!/bin/bash

# 字幕文件整合处理脚本（V1.0）
# 功能：
# 1. 搜索三层内的SRT文件到指定文件夹（自动跳过已存在的目标文件夹）
# 2. 可选择删除.英文.srt后缀文件
# 3. 支持自定义重命名规则（后续会增加一键添加到mp4、mkv等视频文件）（后续支持一键修改infuse、emby识别字幕格式）
# 作者：JamesJordyn
# 说明：本脚本开源，可自由修改，但请保留原作者信息

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 显示标题
echo -e "${GREEN}===== 字幕文件整合处理工具 ====${NC}"
echo -e "${BLUE}作者：JamesJordyn${NC}"
echo -e "${BLUE}说明：本脚本开源，可自由修改，但请保留原作者信息${NC}"
echo "本工具将帮助您整理、筛选和重命名字幕文件"
echo "======================================="

# 1. 获取目标文件夹名称
read -p "请输入存放SRT文件的目标文件夹名称: " target_folder
if [[ -z "$target_folder" ]]; then
    echo -e "${RED}错误：文件夹名称不能为空!${NC}"
    exit 1
fi

# 2. 处理目标文件夹存在的情况
if [[ -d "$target_folder" ]]; then
    echo -e "${YELLOW}目标文件夹 $target_folder 已存在，将跳过该文件夹搜索SRT文件${NC}"
else
    mkdir -p "$target_folder"
    echo -e "${YELLOW}已创建目标文件夹: $target_folder${NC}"
fi

# 3. 搜索并复制SRT文件（跳过目标文件夹，当前文件夹下三层内）
echo -e "${YELLOW}正在搜索当前文件夹下三层内的SRT文件...${NC}"
srt_files=$(find . -maxdepth 3 -path "./$target_folder" -prune -o -type f -name "*.srt")

if [[ -z "$srt_files" ]]; then
    echo -e "${RED}未找到SRT文件，程序退出${NC}"
    exit 0
fi

# 复制文件到目标文件夹
copy_count=0
for file in $srt_files; do
    cp "$file" "$target_folder/"
    copy_count=$((copy_count + 1))
done

echo -e "${GREEN}已复制 $copy_count 个SRT文件到 $target_folder${NC}"

# 4. 是否删除英语字幕
read -p "是否删除英语字幕文件? (y/n): " delete_english
if [[ $delete_english == [yY] ]]; then
    echo -e "${YELLOW}正在删除.英文.srt后缀文件...${NC}"
    english_files=$(find "$target_folder" -type f -name "*英文.srt")

    if [[ -n "$english_files" ]]; then
        echo "找到以下.英文.srt文件将被删除:"
        echo "$english_files"
        read -p "确认删除? (y/n): " confirm
        if [[ $confirm == [yY] ]]; then
            find "$target_folder" -type f -name "*英文.srt" -delete
            del_count=$(echo "$english_files" | wc -l)
            echo -e "${GREEN}已删除 $del_count 个.英文.srt文件${NC}"
        else
            echo -e "${YELLOW}已取消删除操作${NC}"
        fi
    else
        echo -e "${GREEN}未找到.英文.srt文件，无需删除${NC}"
    fi
else
    echo -e "${YELLOW}已跳过删除英语字幕操作${NC}"
fi

# 5. 自定义重命名规则
echo -e "${YELLOW}===== 开始自定义重命名 ====${NC}"
echo "请按行输入重命名规则，每行格式为 '查找内容|替换内容'"
echo "例如: .720p.|.1080p."
echo "输入空行结束规则输入"

# 获取用户输入的重命名规则
rules=()
while true; do
    read -p "请输入重命名规则: " rule
    if [[ -z "$rule" ]]; then
        break
    fi
    rules+=("$rule")
done

if [[ ${#rules[@]} -eq 0 ]]; then
    echo -e "${YELLOW}未输入重命名规则，跳过重命名操作${NC}"
    exit 0
fi

# 显示规则预览
echo -e "${YELLOW}您输入的重命名规则:${NC}"
for i in "${!rules[@]}"; do
    echo "$((i+1)). ${rules[$i]}"
done

# 执行重命名
echo -e "${YELLOW}正在预览重命名效果...${NC}"
renamed_count=0
preview=()
for file in "$target_folder"/*.srt; do
    if [[ -f "$file" ]]; then
        temp_file="$file"
        for rule in "${rules[@]}"; do
            find_str="${rule%%|*}"
            replace_str="${rule##*|}"
            temp_file=$(echo "$temp_file" | sed "s/$find_str/$replace_str/g")
        done
        if [[ "$file" != "$temp_file" ]]; then
            preview+=("$file $temp_file")
            renamed_count=$((renamed_count + 1))
        fi
    fi
done

if [[ $renamed_count -eq 0 ]]; then
    echo -e "${GREEN}没有文件需要重命名${NC}"
    exit 0
fi

echo "以下文件将被重命名:"
for p in "${preview[@]}"; do
    old_file="${p%% *}"
    new_file="${p##* }"
    echo "重命名: ${old_file} -> ${new_file}"
done

read -p "确认执行重命名? (y/n): " confirm
if [[ $confirm == [yY] ]]; then
    echo -e "${YELLOW}正在执行重命名...${NC}"
    rename_count=0
    for file in "$target_folder"/*.srt; do
        if [[ -f "$file" ]]; then
            temp_file="$file"
            for rule in "${rules[@]}"; do
                find_str="${rule%%|*}"
                replace_str="${rule##*|}"
                temp_file=$(echo "$temp_file" | sed "s/$find_str/$replace_str/g")
            done
            if [[ "$file" != "$temp_file" ]]; then
                mv "$file" "$temp_file"
                rename_count=$((rename_count + 1))
            fi
        fi
    done
    echo -e "${GREEN}已完成 $rename_count 个文件的重命名${NC}"
else
    echo -e "${YELLOW}已取消重命名操作${NC}"
fi

# 显示最终结果
echo -e "${GREEN}===== 处理完成 ====${NC}"
echo "目标文件夹: $target_folder"
echo "文件夹中的SRT文件列表:"
ls -la "$target_folder" | grep ".srt$"
