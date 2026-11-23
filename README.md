# 7sProMax ZMK config (draft)

7sProMax（Salicylic-acid3）を BLE Micro Pro（無印・昇圧なし版）×2 で
ZMK 化するための config ドラフト。**ローカルドラフトであり、未ビルド・実機未確認。**
調査の根拠と未確認事項は [NOTES.md](NOTES.md) を参照。

## 構成

- `boards/arm/ble_micro_pro/` — 無印 BMP 用ボード定義
  （`koorayworks/zmk-config-corne-v2-bmp` から複製）
- `config/west.yml` — ZMK は cormoran フォーク v0.3 系の固定リビジョン
- `config/boards/shields/7spromax/` — 7sProMax シールド
  - kscan: 片手 5行×8列、駆動 = Pro Micro D4–D8、読取 = A3,A2,A1,A0,D15,D14,D16,D9、COL2ROW
  - 共有トランスフォーム 10行×8列（左 = 行 0–4、右 = 行 5–9、右は row-offset 5）
- `config/7spromax.keymap` — テスト用キーマップ
  （全 80 ポジションに異なるキーを割り当て、物理キーと (row, col) の対応を
  実機で特定するためのもの。system レイヤーに `&bootloader` 等あり）

前提: **central は左手側**（= ケース呼称 short の推定。NOTES.md §4）。

## ビルド（想定手順、未実施）

ZMK v0.3 系ワークスペースで、このフォルダを config として使う:

```sh
west build -s zmk/app -b ble_micro_pro -d build/7spromax_left -- \
  -DSHIELD=7spromax_left -DZMK_CONFIG=$PWD/config
west build -s zmk/app -b ble_micro_pro -d build/7spromax_right -- \
  -DSHIELD=7spromax_right -DZMK_CONFIG=$PWD/config
```

## 書き込み

BMP（無印）は RES を GND に短絡したまま USB 接続すると `BLEMICROPRO`
ドライブとして現れるので、UF2 をコピーする。
Corne 用ファームから載せ替える場合は、先に settings_reset の UF2 を
焼いて設定を消すこと（NOTES.md §9）。
