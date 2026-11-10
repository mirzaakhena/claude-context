#!/bin/bash
# Memasang claude-context:
#   1. skill `konteks` -> ~/.claude/skills/konteks (symlink ke repo ini)
#   2. statusLine di ~/.claude/settings.json dibungkus rekam-statusline.sh,
#      dengan statusline lama tetap dipanggil. Cadangan settings disimpan dulu.
# Aman dijalankan berulang.

set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
settings="$HOME/.claude/settings.json"
pembungkus="$repo/bin/rekam-statusline.sh"

command -v jq >/dev/null || { echo "jq belum terpasang (brew install jq)." >&2; exit 1; }
chmod +x "$repo/bin/"*.sh

# 1. Skill
mkdir -p "$HOME/.claude/skills"
ln -sfn "$repo/skills/konteks" "$HOME/.claude/skills/konteks"
echo "Skill   : ~/.claude/skills/konteks -> $repo/skills/konteks"

# 2. Statusline
[ -f "$settings" ] || echo '{}' > "$settings"
lama=$(jq -r '.statusLine.command // empty' "$settings")

case "$lama" in
    "$pembungkus"*)
        echo "Statusline: sudah dibungkus, tidak diubah."
        exit 0 ;;
esac

cadangan="$settings.sebelum-claude-context.$(date +%Y%m%d%H%M%S)"
cp "$settings" "$cadangan"

baru="$pembungkus${lama:+ $lama}"
jq --arg c "$baru" '.statusLine = ((.statusLine // {}) + {type: "command", command: $c})' "$settings" > "$settings.tmp"
mv "$settings.tmp" "$settings"

echo "Statusline: $baru"
echo "Cadangan  : $cadangan"
echo "Rekaman muncul di ~/.claude/claude-context/ begitu statusline digambar ulang."
