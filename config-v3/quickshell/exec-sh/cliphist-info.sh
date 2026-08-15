#!/usr/bin/env bash

# 设置图片缓存目录
CLIPBOARD_DIR="${XDG_RUNTIME_DIR:-/tmp}/quickshell/clipboard"
mkdir -p "$CLIPBOARD_DIR"

# JSON 转义函数
escape_json() {
	local s="$1"
	s="${s//\\/\\\\}"
	s="${s//\"/\\\"}"
	s="${s//$'\n'/\\n}"
	s="${s//$'\r'/\\r}"
	s="${s//$'\t'/\\t}"
	printf "%s" "$s"
}

# URL 解码函数
urldecode() {
	python3 -c "import urllib.parse, sys; print(urllib.parse.unquote(sys.argv[1]))" \
		"$1" 2>/dev/null || echo "$1"
}

# 去除首尾空白字符
trim() {
	local s="$1"
	s="${s#"${s%%[![:space:]]*}"}"
	s="${s%"${s##*[![:space:]]}"}"
	printf "%s" "$s"
}

# 获取真实 MIME
get_mime() {
	file --brief --mime-type "$1" 2>/dev/null
}

# 判断是否图片
is_image_mime() {
	[[ "$1" == image/* ]]
}

# ============================================================
# 将任意图片转换成 PNG，并保存到 clipboard cache
#
# 输入：
#   $1 = 原始图片文件
#
# 输出：
#   stdout = PNG 文件路径
# ============================================================
cache_image_as_png() {
	local input="$1"

	if [[ ! -f "$input" ]]; then
		return 1
	fi

	local mime
	mime=$(get_mime "$input")

	if ! is_image_mime "$mime"; then
		return 1
	fi

	# 使用文件内容 hash，避免相同图片重复生成
	local hash
	hash=$(sha256sum "$input" | awk '{print $1}')

	local output="$CLIPBOARD_DIR/${hash}.png"

	# 已经缓存过
	if [[ -s "$output" ]]; then
		printf "%s" "$output"
		return 0
	fi

	# PNG 可以直接复制
	if [[ "$mime" == "image/png" ]]; then
		cp "$input" "$output"
	else
		# 其他图片统一转换成 PNG
		if ! magick "$input" "$output" 2>/dev/null; then
			rm -f "$output"
			return 1
		fi
	fi

	# 确认输出确实是 PNG
	if [[ ! -s "$output" ]]; then
		rm -f "$output"
		return 1
	fi

	local output_mime
	output_mime=$(get_mime "$output")

	if [[ "$output_mime" != "image/png" ]]; then
		rm -f "$output"
		return 1
	fi

	printf "%s" "$output"
}

echo "["
first=true

while IFS=$'\t' read -r id preview; do
	type="text"
	content="$preview"
	mime="text/plain"

	# ============================================================
	# 1. file:// 类型
	# ============================================================

	if [[ "$preview" == file://* ]]; then

		filepath=$(urldecode "${preview#file://}")
		filepath=$(trim "$filepath")

		if [[ -f "$filepath" ]]; then

			real_mime=$(get_mime "$filepath")

			if is_image_mime "$real_mime"; then

				# 无论原始文件是什么格式：
				# JPEG / WEBP / BMP / GIF / TIFF / PNG ...
				# 最终统一保存成 PNG
				cached=$(cache_image_as_png "$filepath")

				if [[ -n "$cached" && -f "$cached" ]]; then
					type="image"
					content="$cached"
					mime="image/png"
				else
					type="file"
					content="$filepath"
					mime="$real_mime"
				fi

			else
				type="file"
				content="$filepath"
				mime="$real_mime"
			fi

		else
			# 原文件已经不存在
			type="text"
			content="$filepath"
			mime="text/plain"
		fi

	# ============================================================
	# 2. 绝对路径
	# ============================================================

	elif [[ "$preview" == /* ]]; then

		local_path=$(trim "$preview")

		if [[ -f "$local_path" ]]; then

			real_mime=$(get_mime "$local_path")

			if is_image_mime "$real_mime"; then

				cached=$(cache_image_as_png "$local_path")

				if [[ -n "$cached" && -f "$cached" ]]; then
					type="image"
					content="$cached"
					mime="image/png"
				else
					type="file"
					content="$local_path"
					mime="$real_mime"
				fi

			else
				type="file"
				content="$local_path"
				mime="$real_mime"
			fi
		fi

	# ============================================================
	# 3. cliphist 二进制图片
	# ============================================================

	elif [[ "$preview" == *"binary data"* && "$preview" == *"image"* ]] ||
		[[ "$preview" == "[[ binary data"* ]]; then

		type="image"

		# 先 decode 到临时文件
		tmpfile=$(mktemp "$CLIPBOARD_DIR/.decode.XXXXXX")

		if printf "%s\t%s\n" "$id" "$preview" | cliphist decode >"$tmpfile"; then

			if [[ -s "$tmpfile" ]]; then

				# 检测真实 MIME
				real_mime=$(get_mime "$tmpfile")

				if is_image_mime "$real_mime"; then

					# ------------------------------------------------
					# 重点：
					#
					# 不管原始图片是：
					#   PNG
					#   JPEG
					#   WEBP
					#   BMP
					#   GIF
					#   TIFF
					#   ...
					#
					# 最终全部转换成 PNG
					# ------------------------------------------------

					cached=$(cache_image_as_png "$tmpfile")

					if [[ -n "$cached" && -f "$cached" ]]; then
						content="$cached"
						mime="image/png"
					else
						type="text"
						content="$preview"
						mime="text/plain"
					fi

				else
					type="text"
					content="$preview"
					mime="text/plain"
				fi

			else
				type="text"
				content="$preview"
				mime="text/plain"
			fi

		else
			type="text"
			content="$preview"
			mime="text/plain"
		fi

		rm -f "$tmpfile"
	fi

	# ============================================================
	# 输出 JSON
	# ============================================================

	if [ "$first" = true ]; then
		first=false
	else
		echo ","
	fi

	esc_id=$(escape_json "$id")
	esc_type=$(escape_json "$type")
	esc_mime=$(escape_json "$mime")
	esc_content=$(escape_json "$content")
	esc_preview=$(escape_json "$preview")

	echo "  {"
	echo "    \"id\": \"$esc_id\","
	echo "    \"type\": \"$esc_type\","
	echo "    \"mime\": \"$esc_mime\","
	echo "    \"content\": \"$esc_content\","
	echo "    \"preview\": \"$esc_preview\""
	echo -n "  }"

done < <(cliphist list)

echo ""
echo "]"
