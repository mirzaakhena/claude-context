# claude-context

Supaya Claude bisa menjawab "konteksmu sudah terpakai berapa?" dengan angka
yang sama dengan statusline, bukan tebakan.

## Masalahnya

Persentase konteks, ukuran jendela, dan kuota 5 jam / 7 hari hanya dikirim
Claude Code ke **stdin perintah statusline**. Transkrip sesi hanya memuat
jumlah token per balasan, tanpa ukuran jendelanya. Dari dalam percakapan,
Claude tidak punya jalan ke angka itu.

## Cara kerjanya

```
Claude Code ──JSON──▶ bin/rekam-statusline.sh ──▶ statusline lama (tampilan sama)
                              │
                              └─▶ ~/.claude/claude-context/<session_id>.json
                                                  ▲
skill `konteks` ──▶ bin/konteks.sh ───────────────┘  (+ transkrip sebagai cadangan)
```

- `bin/rekam-statusline.sh` — pembungkus statusline: menyimpan JSON per sesi,
  lalu meneruskannya ke statusline asli.
- `bin/konteks.sh` — membaca rekaman sesi `$CLAUDE_CODE_SESSION_ID` dan
  mencetak konteks terpakai/tersisa, ukuran jendela, kuota 5 jam / 7 hari dan
  kapan pulih, model, biaya. Tanpa rekaman, ia hanya bisa memberi jumlah token
  dari transkrip.
- `skills/konteks/` — skill yang menyuruh Claude menjalankan skrip itu.

## Pasang

```bash
bash install.sh
```

Skrip ini membuat symlink `~/.claude/skills/konteks`, lalu membungkus
`statusLine.command` di `~/.claude/settings.json`; statusline lama tetap
dipanggil. Cadangan settings disimpan dulu. Aman dijalankan berulang.
Lepas lagi dengan `bash uninstall.sh`.

Sesudah pasang, mulai sesi baru (atau tunggu statusline digambar ulang), lalu
tanya Claude: "konteksmu berapa?".

## Pakai langsung

```bash
bin/konteks.sh                 # sesi $CLAUDE_CODE_SESSION_ID
bin/konteks.sh <session_id>    # sesi lain
bin/konteks.sh --json          # rekaman mentah dari statusline
```

Butuh `jq`.
