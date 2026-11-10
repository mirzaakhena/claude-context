#!/bin/bash
# Pembungkus statusline Claude Code.
#
# Claude Code mengirim JSON berisi keadaan sesi (persentase konteks, ukuran
# jendela, kuota 5 jam / 7 hari, dll.) ke stdin perintah statusline. Data itu
# tidak tersimpan di mana pun selain di situ, jadi pembungkus ini:
#   1. menyimpan salinannya ke $CLAUDE_CONTEXT_DIR/<session_id>.json
#      (bawaan ~/.claude/claude-context/), supaya skill `konteks` bisa membacanya;
#   2. meneruskan JSON yang sama ke statusline asli (argumen pertama), sehingga
#      tampilan statusline tidak berubah.
#
# Pemakaian di settings.json:
#   "statusLine": { "type": "command",
#     "command": "/path/claude-context/bin/rekam-statusline.sh /path/statusline-asli.sh" }

input=$(cat)

dir="${CLAUDE_CONTEXT_DIR:-$HOME/.claude/claude-context}"
sesi=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null)

if [ -n "$sesi" ]; then
    mkdir -p "$dir"
    # Tulis atomik: skill tidak boleh membaca berkas yang setengah jadi.
    tmp="$dir/.$sesi.$$"
    if printf '%s' "$input" | jq --arg t "$(date +%s)" '. + {_direkam_pada: ($t|tonumber)}' > "$tmp" 2>/dev/null; then
        mv -f "$tmp" "$dir/$sesi.json"
    else
        rm -f "$tmp"
    fi
fi

# Teruskan ke statusline asli, bila ada.
if [ -n "$1" ]; then
    printf '%s' "$input" | "$@"
fi
