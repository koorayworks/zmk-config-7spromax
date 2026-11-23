# 7sProMax × BLE Micro Pro（無印）×2 — ZMK 化ドラフト NOTES

作成: 2026-11-23。ローカルドラフト（GitHub 未 push）。
前提: **central は左手側**。左手 = ケース側呼称 **short**、右手 = **long** と置いている（根拠と留保は §4）。

凡例: **確認済み** = 一次情報（公式 config 実物・公式ガイド・実測記録・ファームソース）で裏取りできたもの。
**推定** = 複数の傍証から導いたが直接の裏取りはないもの。**未確認** = まだ情報がないもの。

---

## 1. 土台（確認済み）

- ボード定義 `boards/arm/ble_micro_pro/` は、ユーザーの repo `koorayworks/zmk-config-corne-v2-bmp`
  のものをそのまま複製（BL654 / nRF52840、Pro Micro 互換ピン配置、外付け 32.768kHz クリスタルなし前提）。
- ZMK は同 repo の `config/west.yml` と同じ、cormoran フォークの固定リビジョン
  `4493783ef88ce2e653bf8217c92ee17140df71e3`（ZMK v0.3 系 + DYA 拡張）。
  Corne 専用の追加モジュール（custom-settings / jpkeys）はこのドラフトには入れていない。
- 7sProMax の BLE Micro Pro ×2 完全無線はメーカー公式に想定された構成
  （ビルドガイド: 左手用 =「Is Left」、右手用 =「Is Slave」、LPME は右手のみ）。
  出典: Salicylic-acid3 公式ビルドガイド https://salicylic-acid3.hatenablog.com/entry/7spromax-build-guide

## 2. マトリクス定義（確認済み）

出典は sekigon-gonnoc 公式 WebConfigurator の repo
（`BLE-Micro-Pro-WebConfigurator`、`public/config/salicylic_acid3_7spro_max_{master,slave,lpme}_config.bin`、
commit `84a582d8`）の **バイナリ config 実物をパース**した結果 + LPME エミュレータ作業
（`~/workspace/promicro-lpme-emu/`、BMP ファームソース由来の調査記録）。

config バイナリ内のマトリクス部（オフセットは3ファイル共通）:

| オフセット | 値 | 解釈 |
|---|---|---|
| 3908 | 10 | 全体行数（左右合計） |
| 3909 | 8 | 全体列数 |
| 3910 | 5 | このデバイスの行数（片手分） |
| 3911 | 8 | このデバイスの列数 |
| 3912 | 8 | 未解釈（全ファイル共通で 8） |
| 3913 | 1 | 未解釈（全ファイル共通で 1。分割有効フラグ相当か） |
| 3914 | master=1 / slave=0 / lpme=1 | is_left_hand |
| 3915 | master/slave=0 / lpme=2 | diode_direction（2 = COL2ROW_LPME、エミュレータ調査で確認済み） |
| 3916–3925 | [7,8,9,10,11] + (lpme のみ [7,8,9,10,11] を追加) | row_pins（前半5 = 自手、後半5 = LPME 先の相手手） |
| 3948–3963 | [20,19,18,17,16,15,14,12] + (lpme のみ同列を追加) | col_pins（同上） |

読み取れた事実:

- **片手 5行×8列、全体 10行×8列**。右手の行オフセットは 5
  （BMP ファームの `matrix_basic.c`: 右手の offset = 全体行数 − 自手行数 = 10 − 5）。
  → ZMK の共有トランスフォームも 10×8 とし、右手 overlay で `row-offset = <5>` にした。
- **左右ともローカルマトリクスのピンは同一**（master と slave の bin はピン配列が完全一致。
  違いは is_left_hand とオフセット 3980 の役割値 master=1/slave=2/lpme=0 のみ）。
  LPME 構成でも相手手のピンが同じ並びで繰り返されることから、**両基板とも同じ
  フットプリント位置にマトリクスが配線されている**と分かる。→ シールドの kscan は左右共通。
- 駆動/読取の役割: BMP ファームソース（`matrix_basic.c` の col2row 系、`lpme.c`）より、
  **row_pins 側を駆動（オープンドレイン、アクティブ Low）、col_pins 側を読取（プルアップ入力）**。
- diode_direction: master/slave = 0。値 2 が COL2ROW_LPME と確認できているので、
  0 = COL2ROW とみなす（列挙の並びからの推定を含む。§5 参照）。
  → シールドでは ZMK 上流 Corne シールドと同じ流儀で `diode-direction = "col2row"` とし、
  row-gpios / col-gpios のフラグも Corne シールドに倣った。

ピン変換チェーン（全段確認済み）:

| BMP config 番号 | ATmega32U4 ピン名 | Pro Micro 表記（Arduino 番号） | nRF52840 GPIO |
|---|---|---|---|
| row 7 | D4 | D4 (4) | P0.19 |
| row 8 | C6 | D5 (5) | P0.20 |
| row 9 | D7 | D6 (6) | P0.22 |
| row 10 | E6 | D7 (7) | P0.23 |
| row 11 | B4 | D8 (8) | P1.00 |
| col 20 | F4 | A3 (21) | P0.05 |
| col 19 | F5 | A2 (20) | P0.00 |
| col 18 | F6 | A1 (19) | P0.30 |
| col 17 | F7 | A0 (18) | P0.03 |
| col 16 | B1 | D15 (15) | P1.14 |
| col 15 | B3 | D14 (14) | P1.15 |
| col 14 | B2 | D16 (16) | P0.10 |
| col 12 | B5 | D9 (9) | P1.03 |

- config 番号 → ATmega ピン名: LPME エミュレータ調査（BMP ファームソース由来）で確認済み。
- ATmega → Arduino 番号: 標準 Pro Micro ピン対応。
- Arduino 番号 → nRF GPIO: ユーザーのボード定義 `arduino_pro_micro_pins.dtsi`（gpio-map）そのもの。
- 傍証: この並びは Corne の QMK 標準ピン（row = D4,C6,D7,E6 / col = F4,F5,F6,F7,B1,B3）の
  自然な拡張（行 +B4、列 +B2,B5）になっており、変換ミスがあると崩れるはずの整合が取れている。

## 3. キー数と物理配置（確認済み）

- MX スイッチ **63 個**（公式ガイドの必要数と一致）。
  ケースプロジェクトの実測（公式ケース図面 DXF + 実基板裏面スキャン照合、RMS 0.07–0.11mm）では
  **short 28 穴 / long 35 穴**。出典: `~/workspace/7spromax-case/design/board_reference.md`。
- 行（奥行方向）ごとの穴数は short = 6/6/6/6/4、long = 9/8/7/7/4 で、
  合計すると 15/14/13/13/8 となり HHKB 系配列の行構成と一致する（穴座標からの導出）。
- スタビライザー用スロット: short 2 点（2u スペース想定位置）/ long 4 点。

## 4. long / short と手の対応（推定）

- **推定: short = 左手、long = 右手。**
  根拠: ケースプロジェクトの `board_reference.md` の見取り図が「表面を上から見た図」で
  **short を左・long を右に置き、階段側が中央で噛み合う**向きで描かれている
  （公式ケース図面由来の組み立て完成形の図）。ただし「short = 左手」と明言した一次資料は未発見。
- 留保: 実機のボトムプレートには「L」「R」の刻印がある（公式ガイド）。実機で
  L プレートが付く側の基板が short か long かを確認すれば確定する。
- もし逆だった場合の影響: central（左手）が long 側になる。シールドの left/right の
  対応付けと、右手の row-offset の付け先を入れ替えるだけで済む（kscan 自体は左右同一）。
- なお BMP が既に実装されているのは short 基板側（2026-11-23 実機写真）。
  short = 左手なら、そのまま short 側が central になる。

## 5. タクト（エクストラ）スイッチ（確認済み + 未確認）

- エクストラスイッチは左右各 3 個、計 6 個（公式ガイドの内容物一覧）。
  ケース上部（マイコン側の端）に差し込み、ケース内部のプランジャが基板上の
  タクトスイッチを押す構造（公式 IC 記事 + ケースプロジェクト実測:
  両半分とも中心 X ≈ 111.5、ピッチ 10.0mm、基板端から最近中心まで short 14.50mm / long 14.00mm）。
- **マトリクスに含まれることは確認済み（間接）**: 公式ガイドに「7sProMax に 7sKB / 7sPro の
  ファームウェアを使うとエクストラスイッチは使えなくなる」とあり、7sProMax 用ファームでは
  キーとして機能する。想定用途はマクロ / LED / 無線切替など（公式 IC 記事）。
- **未確認: 各タクトの (row, col)**。LPME エミュレータ調査でも右手分は未特定だった。
  容量の見積もりでは片手 5×8 = 40 ポジションに対し long = 35 + 3 = 38、short = 28 + 3 = 31 で
  収まるため、マトリクス内の空きポジションに入っている可能性が高い（推定）。
  → テストキーマップで全ポジションを叩けば実機で特定できる。

## 6. その他の確認済み事項

- BMP の実装はバッテリピンの分だけ **1 ピンずらして**フットプリントに載る（公式ガイド）。
  基板側はその前提で設計されている。ZMK ボード定義の pro_micro コネクタはモジュール側の
  ピン並びを表すため、シールド側でずらす必要はない（Corne での実績どおり）。
- TRRS は ZMK の BLE 分割では使わない（左右間は BLE）。有線 Pro Micro 構成や
  LPME 構成でのみ意味を持つ配線なので、ドラフトでは未対応で問題ない。
- 書き込み手順（BMP 無印）: RES を GND に短絡したまま USB 接続 → `BLEMICROPRO`
  ドライブへ UF2 をコピー（sekigon 公式ドキュメント / 回路図で確認済み）。
  キーマップ側にも `&bootloader` を用意した（system レイヤー）が、初回は RES 短絡が確実。

## 7. 推定事項まとめ

1. short = 左手 / long = 右手（§4）。
2. diode_direction = 0 は COL2ROW（2 = COL2ROW_LPME からの類推）。
3. タクト 3 個/半分は 5×8 マトリクス内の空きポジションに入っている（§5）。
4. LED は WS2812 系で片手 16 個（config bin オフセット 3986–3987 の値 16 が
   3 ファイル共通。ソフマップ商品仕様の「LED 数 16 個」とも一致するが、片手分か全体かは不明）。
   LED ピンは BMP config 番号 1（LPME エミュレータ調査、右手側の記述）。
   このドラフトでは LED は未実装。

## 8. 未確認事項

1. **各物理キーの (row, col) 対応**（最重要）。公式の Vial デフォルトキーマップ
   （Google Drive 配布）や Remap 定義を入手できれば事前に確定できるが、未入手。
   現行ドラフトのトランスフォームは「行優先の素直な並び」で、実キーの位置とは一致しない前提。
   テストキーマップで全ポジション異なるキーを割り当ててあるので、実機で押して対応表を作る。
2. タクトスイッチ 3 個/半分の (row, col)（上記 1 に含む）。
3. ZMK kscan の diode-direction / GPIO フラグが実機でそのまま通るか
   （初回起動確認ポイント。反応しない・ゴーストが出る場合はここを見直す）。
4. 電池まわり: 公式の電池部品セット（CR1632 ケース、スライドスイッチ、SB ダイオード、
   コンデンサ）使用時の配線と、ZMK の電池電圧取得（分圧ピン）の定義。ドラフトでは未対応
   （USB 給電前提。Corne 用ボード定義にも電池分圧の定義はない）。
5. ZMK Studio 対応: 土台の DYA フォークは Studio 拡張を含むが、このドラフトの west.yml では
   Corne 用の custom-settings モジュールを外したため、Studio 連携は未検証・未設定。
6. config bin の未解釈フィールド（オフセット 3912 = 8、3913 = 1、3980 の役割値、
   3981 以降の LED 相当領域）。マトリクス定義には影響しない見込みだが未解釈のまま記録する。

## 9. 実機投入時の注意（手順メモ）

- この BMP 2 個は現在 Corne v2 用 ZMK ファームが入っており、ペアリング等の設定が
  storage 領域に残っている。7sProMax 用を焼く前に **settings_reset の UF2 を先に焼く**
  のが安全（左右とも）。
- 初回は RES-GND 短絡（短絡したまま USB 挿し）でブートローダに入り、
  左手（central 想定 = short 側）に `7spromax_left`、右手に `7spromax_right` の UF2 を焼く。
- TRRS は繋がない（BLE 分割では不要。通電中の抜き差しは公式ガイドでも禁止事項）。

## 10. 出典一覧

- sekigon-gonnoc/BLE-Micro-Pro-WebConfigurator `public/config/salicylic_acid3_7spro_max_*_config.bin`（実物パース）
- sekigon-gonnoc/qmk_firmware（dev/ble_micro_pro）の `matrix_basic.c` / `matrix_lpme.c` / `lpme.c`
  （ローカル写し: `~/workspace/promicro-lpme-emu/research/`、同 repo の README の調査まとめ）
- Salicylic-acid3 公式ビルドガイド（hatenablog、2024-11-22 公開 / 2026-11-07 更新）
- Salicylic-acid3 7sProMax インタレストチェック記事（エクストラスイッチの構造・用途）
- `~/workspace/7spromax-case/design/board_reference.md`（穴数・タクト位置の実測）
- `koorayworks/zmk-config-corne-v2-bmp`（ボード定義・west.yml の土台）
