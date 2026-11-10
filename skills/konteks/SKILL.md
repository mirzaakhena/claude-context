---
name: konteks
description: Laporkan berapa konteks sesi Claude Code ini yang sudah terpakai dan tersisa, ukuran jendelanya, serta kuota pemakaian 5 jam / 7 hari dan kapan pulih — angka yang sama dengan statusline. Pakai setiap kali pengguna bertanya "konteksmu berapa", "sisa konteks", "sudah pakai berapa", "kuota/usage tinggal berapa", "kapan reset", atau sebelum memutuskan menulis catatan serah-terima karena konteks menipis. Jangan menebak persentase dari dalam; jalankan skrip ini.
---

# konteks

Jalankan skripnya, lalu sampaikan hasilnya apa adanya:

```bash
"${CLAUDE_SKILL_DIR:-$HOME/.claude/skills/konteks}/../../bin/konteks.sh"
```

Bila `CLAUDE_SKILL_DIR` tidak ada dan jalur di atas gagal, cari skripnya:
`readlink -f ~/.claude/skills/konteks` lalu `../../bin/konteks.sh` dari situ.

## Cara membaca hasilnya

- **Sumber: rekaman statusline** — angka persis seperti statusline. Sebut
  umurnya ("diperbarui N detik lalu"): rekaman diperbarui setiap statusline
  digambar ulang, jadi bisa tertinggal satu-dua balasan dari keadaan sekarang.
- **Sumber: transkrip saja** — pembungkus statusline belum terpasang atau belum
  sempat menulis. Hanya jumlah token yang pasti; persentase hanya dua
  kemungkinan (200 ribu / 1 juta). Katakan itu, jangan pilih salah satu.
- Kuota 5 jam / 7 hari hanya muncul bila Claude Code mengirimnya ke statusline
  (bergantung paket akun).

`konteks.sh --json` mencetak rekaman mentah bila pengguna ingin melihat semua
medan yang dikirim Claude Code.

## Batas

Angka konteks dari transkrip adalah token pada balasan terakhir yang tercatat,
belum termasuk balasan yang sedang ditulis. Jangan menambah perkiraan sendiri.
