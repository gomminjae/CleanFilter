#!/bin/bash

INPUT_JSON="$SRCROOT/Resources/filters_meta.json"
OUTPUT_DIR="$SRCROOT/Filters/Generated"
CACHE_DIR="$OUTPUT_DIR/.cache"

mkdir -p "$OUTPUT_DIR"
mkdir -p "$CACHE_DIR"

FILTERS=$(jq -c '.[]' "$INPUT_JSON")

for row in $FILTERS; do
  ID=$(echo "$row" | jq -r '.shader')
  PARAMS=$(echo "$row" | jq -c '.parameters')
  FORMULA=$(echo "$row" | jq -r '.formula[]')

  # 🔐 해시 계산
  HASH=$(echo "$row" | shasum -a 256 | cut -d ' ' -f 1)
  HASH_FILE="$CACHE_DIR/${ID}.hash"

  # ✅ 변경 없으면 스킵
  if [[ -f "$HASH_FILE" ]]; then
    OLD_HASH=$(cat "$HASH_FILE")
    if [[ "$OLD_HASH" == "$HASH" ]]; then
      echo "🟡 Skipped ${ID} (unchanged)"
      continue
    fi
  fi

  # 🔧 Uniform 구조 생성
  STRUCT="struct Uniforms {\n"
  while read -r param; do
    NAME=$(echo "$param" | jq -r '.name')
    TYPE=$(echo "$param" | jq -r '.type')
    STRUCT+="    ${TYPE} ${NAME};\n"
  done <<< "$(echo $PARAMS | jq -c '.[]')"
  STRUCT+="};"

  # 🧠 Metal 쉐이더 코드 생성
  METAL_CODE="#include <metal_stdlib>
using namespace metal;

$STRUCT

kernel void ${ID}(
    texture2d<float, access::read> inTexture [[ texture(0) ]],
    texture2d<float, access::write> outTexture [[ texture(1) ]],
    constant Uniforms& uniforms [[ buffer(0) ]],
    uint2 gid [[ thread_position_in_grid ]]
) {
    if (gid.x >= inTexture.get_width() || gid.y >= inTexture.get_height()) return;
    float4 color = inTexture.read(gid);
"

  while read -r line; do
    METAL_CODE+="    $line\n"
  done <<< "$FORMULA"

  METAL_CODE+="    color = saturate(color);
    outTexture.write(color, gid);
}
"

  # 📁 .metal 파일 저장 + 해시 캐시
  echo -e "$METAL_CODE" > "$OUTPUT_DIR/${ID}.metal"
  echo "$HASH" > "$HASH_FILE"
  echo "✅ Rebuilt ${ID}.metal"
done

