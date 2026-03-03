#!/bin/bash
# Claude Code Status Line - 显示 token 使用和成本信息

input=$(cat)

# 提取信息
MODEL=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
COST=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')
INPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')
OUTPUT_TOKENS=$(echo "$input" | jq -r '.context_window.total_output_tokens // 0')
USED_PERCENT=$(echo "$input" | jq -r '.context_window.used_percentage // 0')
CACHE_READ=$(echo "$input" | jq -r '.context_window.cache_read_tokens // 0')

# 格式化数字
format_tokens() {
    local num=$1
    if [ "$num" -ge 1000000 ]; then
        printf "%.1fM" $(echo "scale=1; $num/1000000" | bc)
    elif [ "$num" -ge 1000 ]; then
        printf "%.1fK" $(echo "scale=1; $num/1000" | bc)
    else
        echo "$num"
    fi
}

IN_FMT=$(format_tokens "$INPUT_TOKENS")
OUT_FMT=$(format_tokens "$OUTPUT_TOKENS")
CACHE_FMT=$(format_tokens "$CACHE_READ")

# 格式化输出
printf "📊 %s | In:%s Out:%s Cache:%s | 💰$%.4f | 📈%.0f%%" "$MODEL" "$IN_FMT" "$OUT_FMT" "$CACHE_FMT" "$COST" "$USED_PERCENT"
