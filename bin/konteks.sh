#!/bin/bash
# Laporan pemakaian konteks dan kuota untuk satu sesi Claude Code.
#
#   konteks.sh [session_id]     (bawaan: $CLAUDE_CODE_SESSION_ID)
#   konteks.sh --json [id]      cetak rekaman mentah statusline
#
# Sumber angka, berurutan:
#   1. Rekaman statusline ($CLAUDE_CONTEXT_DIR/<id>.json) yang ditulis
#      rekam-statusline.sh: persentase, ukuran jendela, kuota 5 jam / 7 hari
#      persis seperti yang dilihat statusline.
#   2. Transkrip sesi (~/.claude/projects/*/<id>.jsonl): jumlah token konteks
#      pada balasan terakhir. Ukuran jendela tidak tercatat di sana, jadi
#      persentasenya tidak bisa dihitung dari sumber ini saja.

set -u
mentah=0
if [ "${1:-}" = "--json" ]; then mentah=1; shift; fi

sesi="${1:-${CLAUDE_CODE_SESSION_ID:-}}"
dir="${CLAUDE_CONTEXT_DIR:-$HOME/.claude/claude-context}"

if [ -z "$sesi" ]; then
    echo "Tidak tahu sesi mana: CLAUDE_CODE_SESSION_ID kosong dan tidak ada argumen." >&2
    exit 2
fi

rekaman="$dir/$sesi.json"

if [ "$mentah" = 1 ]; then
    [ -f "$rekaman" ] && jq . "$rekaman" || { echo "Belum ada rekaman: $rekaman" >&2; exit 1; }
    exit 0
fi

ribuan() { # 130076 -> 130.076
    awk -v n="$1" 'BEGIN{ s=""; while (length(n) > 3) { s="." substr(n, length(n)-2) s; n=substr(n, 1, length(n)-3) } print n s }'
}

sisa_waktu() { # epoch -> "2j 14m" / "3h 4j"
    local s=$(( $1 - $(date +%s) ))
    [ "$s" -le 0 ] && { echo "sudah lewat"; return; }
    local h=$(( s / 86400 )) j=$(( (s % 86400) / 3600 )) m=$(( (s % 3600) / 60 ))
    if [ "$h" -gt 0 ]; then echo "${h} hari ${j} jam"; else echo "${j} jam ${m} menit"; fi
}

echo "Sesi: $sesi"

# --- 1. Rekaman statusline -------------------------------------------------
if [ -f "$rekaman" ]; then
    umur=$(( $(date +%s) - $(jq -r '._direkam_pada // 0' "$rekaman") ))
    echo "Sumber: rekaman statusline, diperbarui ${umur} detik lalu"
    echo

    pct=$(jq -r '.context_window.used_percentage // empty' "$rekaman")
    ukuran=$(jq -r '.context_window.context_window_size // .context_window.size // .context_window.max_tokens // empty' "$rekaman")
    if [ -n "$pct" ]; then
        pct_bulat=$(printf '%.0f' "$pct")
        echo "Konteks terpakai : ${pct_bulat}%"
        echo "Konteks tersisa  : $(( 100 - pct_bulat ))%"
        if [ -n "$ukuran" ]; then
            terpakai=$(jq -r '.context_window.total_input_tokens // empty' "$rekaman")
            if [ -n "$terpakai" ]; then
                echo "Ukuran jendela   : $(ribuan "$ukuran") token ($(ribuan "$terpakai") terpakai, $(ribuan $(( ukuran - terpakai ))) tersisa)"
            else
                terpakai=$(awk -v p="$pct" -v u="$ukuran" 'BEGIN{printf "%d", p*u/100}')
                echo "Ukuran jendela   : $(ribuan "$ukuran") token (≈ $(ribuan "$terpakai") terpakai, ≈ $(ribuan $(( ukuran - terpakai ))) tersisa)"
            fi
        fi
    else
        echo "Konteks          : rekaman tidak memuat context_window.used_percentage"
    fi

    for jendela in "five_hour:Kuota 5 jam      " "seven_day:Kuota 7 hari     "; do
        kunci=${jendela%%:*}; label=${jendela#*:}
        p=$(jq -r ".rate_limits.$kunci.used_percentage // empty" "$rekaman")
        r=$(jq -r ".rate_limits.$kunci.resets_at // empty" "$rekaman")
        if [ -n "$p" ]; then
            p_bulat=$(printf '%.0f' "$p")
            baris="$label: ${p_bulat}% terpakai, $(( 100 - p_bulat ))% tersisa"
            [ -n "$r" ] && baris="$baris, pulih dalam $(sisa_waktu "$r")"
            echo "$baris"
        fi
    done

    model=$(jq -r '.model.display_name // .model.id // empty' "$rekaman")
    [ -n "$model" ] && echo "Model            : $model"
    biaya=$(jq -r '.cost.total_cost_usd // empty' "$rekaman")
    [ -n "$biaya" ] && printf 'Biaya sesi       : US$%.2f (perkiraan Claude Code)\n' "$biaya"
else
    echo "Sumber: transkrip saja — belum ada rekaman statusline di $rekaman"
    echo "        (pasang dulu: lihat README; persentase dan kuota butuh rekaman itu)"
fi

# --- 2. Transkrip ----------------------------------------------------------
transkrip=$( [ -f "$rekaman" ] && jq -r '.transcript_path // empty' "$rekaman" )
[ -z "$transkrip" ] && transkrip=$(ls "$HOME"/.claude/projects/*/"$sesi".jsonl 2>/dev/null | head -1)

if [ -n "$transkrip" ] && [ -f "$transkrip" ]; then
    token=$(jq -r 'select(.type=="assistant" and (.isSidechain|not) and .message.usage!=null)
                   | .message.usage
                   | ((.input_tokens//0) + (.cache_read_input_tokens//0) + (.cache_creation_input_tokens//0))' \
            "$transkrip" 2>/dev/null | tail -1)
    if [ -n "$token" ]; then
        echo
        echo "Dari transkrip   : $(ribuan "$token") token konteks pada balasan terakhir"
        if [ ! -f "$rekaman" ]; then
            echo "                   ≈ $(( token * 100 / 200000 ))% bila jendelanya 200 ribu, ≈ $(( token * 100 / 1000000 ))% bila 1 juta"
        fi
    fi
fi
