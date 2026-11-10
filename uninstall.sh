#!/bin/bash
# Membatalkan install.sh: lepas skill, kembalikan statusLine ke perintah asli.
set -euo pipefail
repo="$(cd "$(dirname "$0")" && pwd)"
settings="$HOME/.claude/settings.json"
pembungkus="$repo/bin/rekam-statusline.sh"

[ -L "$HOME/.claude/skills/konteks" ] && rm "$HOME/.claude/skills/konteks" && echo "Skill dilepas."

lama=$(jq -r '.statusLine.command // empty' "$settings")
case "$lama" in
    "$pembungkus "*)
        asli="${lama#"$pembungkus "}"
        jq --arg c "$asli" '.statusLine.command = $c' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
        echo "Statusline kembali ke: $asli" ;;
    "$pembungkus")
        jq 'del(.statusLine)' "$settings" > "$settings.tmp" && mv "$settings.tmp" "$settings"
        echo "Statusline dihapus (sebelumnya tidak ada)." ;;
    *) echo "Statusline tidak dibungkus; tidak diubah." ;;
esac
echo "Rekaman di ~/.claude/claude-context/ dibiarkan; hapus sendiri bila tak perlu."
