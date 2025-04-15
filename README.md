# RadRotDirBlur_S AviUtl スクリプト

放射ブラー (radial blur), 回転ブラー (rotation blur), 方向ブラー (directional blur) の 3 つを複合したぼかし効果を適用する AviUtl スクリプトです．

[ダウンロードはこちら．](https://github.com/sigma-axis/aviutl_script_RadRotDirBlur_S/releases) [紹介動画．](https://www.nicovideo.jp/watch/sm44874159)

![放射ブラーと回転ブラー，方向ブラー](https://github.com/user-attachments/assets/471485a6-92a2-4f0b-a71c-381577beef54)

![組み合わせてできたブラー効果](https://github.com/user-attachments/assets/9172eeb8-2e64-413d-87a3-b805c704adcd)

- 元画像: https://www.pexels.com/photo/green-leafed-tree-beside-body-of-water-during-daytime-158063

パラメタの組み合わせによっては螺旋ブラーなど，既存のブラー効果を組み合わせるだけではできない効果も可能です．

##  動作要件

- AviUtl 1.10 (1.00 でも動作するはずだが 1.10 推奨)

  http://spring-fragrance.mints.ne.jp/aviutl

- 拡張編集 0.92

  - 0.93rc1 でも動作するはずだが未確認 / 非推奨．

- GLShaderKit

  https://github.com/karoterra/aviutl-GLShaderKit

- **(推奨)** patch.aul (謎さうなフォーク版)

  https://github.com/nazonoSAUNA/patch.aul

  アンカー位置の認識がずれる原因が 1 つ減ります．
  - 設定ファイル `patch.aul.json` で `"switch"` 以下の `"lua"` と `"lua.getvalue"` を `true` (初期値) にしてください．

##  導入方法

以下のフォルダのいずれかに `RadRotDirBlur_S.anm` `RadRotDirBlur_S.lua`, `RadRotDirBlur_S.frag` の 3 つのファイルをコピーしてください．

1. `exedit.auf` のあるフォルダにある `script` フォルダ
1. (1) のフォルダにある任意の名前のフォルダ

##  パラメタの説明

![スクリプトの GUI](https://github.com/user-attachments/assets/2d629b4c-7a50-41f8-96b1-f70cb60fae58)

### `拡大率`

放射ブラーの拡大率を指定します．

% 単位で最小値は `1`, 最大値は `1000`, 初期値は `120`.

### `回転角`

回転ブラーの回転角度を指定します．

単位は度数法で最小値は `-720`, 最大値は `720`, 初期値は `30`.

### `強さ`

[`拡大率`](#拡大率), [`回転角`](#回転角), [`移動方向`](#移動方向) を一律に強めたり弱めたりします．負の方向にすると，拡大が縮小になったり，回転方向や移動方向が逆になります．

% 単位で最小値は `-200`, 最大値は `200`, 初期値は `100`.

### `相対位置`

ぼかしが広がる範囲の起点を指定します．

`0` で前後に同じ量だけ広がります．`+100` で前方向にだけ広がります．`-100` で後ろ方向にだけ広がります．

最小値は `-100`, 最大値は `100`, 初期値は `0`.

### `サイズ固定`

ぼかし効果で画像サイズが拡大するかどうかを指定します．初期値はチェックなし．

- チェックなしの場合，上下左右に最低 1 ピクセルは画像サイズが引き延ばされます (`強さ` が `0` など一切ぼかし効果のかからない場合を除く).

### `移動方向`

方向ブラーの移動方向・長さを，`{ X座標 , Y座標 }` の形で指定します．

AviUtl メインウィンドウのアンカー操作でも指定できます．
- [`中心`](#中心) もアンカーがありますが，オブジェクト中心からラインが*伸びている*ほうが `移動方向` です．

ピクセル単位で，初期値は `{100,100}`.

### `中心`

放射ブラーと回転ブラーの中心を，`{ X座標 , Y座標 }` の形で指定します．

AviUtl メインウィンドウのアンカー操作でも指定できます．
- [`移動方向`](#移動方向) もアンカーがありますが，オブジェクト中心からラインが*伸びていない*ほうが `中心` です．

ピクセル単位で，初期値は `{0,0}`.

### `精度`

ぼかし計算処理の繰り返し回数を指定します．大きいほど計算精度が高くなりますが，処理が重くなります．拡大・回転・移動方向によるピクセル移動量を超えた値を指定しても，最終結果の精度にはあまり影響がありません．

最小値は `2`, 最大値は `4096` 初期値は `512`.

### `PI`

パラメタインジェクション (parameter injection) です．初期値は `nil`. テーブル型を指定すると `obj.check0` や `obj.track0` などの代替値として使用されます．また，任意のスクリプトコードを実行する記述領域にもなります．

```lua
{
  [0] = check0, -- boolean 型 で "サイズ固定" の項目を上書き，または nil. 0 を false, 0 以外を true 扱いとして number 型も可能．
  [1] = track0, -- number 型で "拡大率" の項目を上書き，または nil.
  [2] = track1, -- number 型で "回転角" の項目を上書き，または nil.
  [3] = track2, -- number 型で "強さ" の項目を上書き，または nil.
  [4] = track3, -- number 型で "相対位置" の項目を上書き，または nil.
}
```

##  他スクリプトから利用する場合

このぼかし効果を他スクリプトから利用できます．`RadRotDirBlur_S.lua` を利用する側のスクリプトが見つけられるようにして置いた上で，以下のようにして適用できます．

```lua
local RadRotDirBlur_S = require "RadRotDirBlur_S";
RadRotDirBlur_S.RadRotDirBlur_S(radial_rate, rotate_rad, direction_x, direction_y, center_x, center_y, relative_pos, quality, keep_size, reload);
```

メインとなる `.RadRotDirBlur_S()` 関数に加えていくつか関数を出力しています．

### `.RadRotDirBlur_S()` 関数

放射・回転・方向の複合ブラーを適用．必要なら画像サイズを領域拡張する．

|引数・戻り値|名前|型|説明|
|---:|:---:|:---:|:---|
|引数 \#1|`radial_rate`|number|拡大率，正数で指定，等倍は `1.0`. 放射ブラーに対応する部分．|
|引数 \#2|`rotate_rad`|number|回転角，ラジアン単位，時計回りに正．回転ブラーに対応する部分．|
|引数 \#3|`direction_x`|number|X 座標の移動量，ピクセル単位，正で右方向．方向ブラーに対応する部分．|
|引数 \#4|`direction_y`|number|Y 座標の移動量，ピクセル単位，正で下方向．方向ブラーに対応する部分．|
|引数 \#5|`center_x`|number|拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点，右に正．|
|引数 \#6|`center_y`|number|拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点，下に正．|
|引数 \#7|`relative_pos`|number|ぼかし処理の基準位置，`0` で両端から伸びるように，`1.0` や `-1.0` で片側から伸びるようにぼかしがかかる．範囲は `-1.0` から `1.0`.|
|引数 \#8|`quality`|integer|1 ピクセルを計算するのに利用されるピクセル数．最小は `2`.|
|引数 \#9|`keep_size`|boolean|サイズ固定をするかどうかを指定．固定しない場合，基本的には最低でも上下左右 1 ピクセルずつ拡大する．|
|引数 \#10|`reload`|boolean\|nil|GLShaderKit に対してシェーダーファイルの再読み込みを促す．デバッグ用．省略時は `false` と同等．|
|戻り値|||なし|

このブラー効果のメインとなる関数です．

```lua
RadRotDirBlur_S.RadRotDirBlur_S(radial_rate, rotate_rad, direction_x, direction_y, center_x, center_y, relative_pos, quality, keep_size, reload);
```

### `.rad_rot_dir_blur()` 関数

拡大率・回転角・座標位置の移動元・移動先を指定し，その変化に沿ったブラーを適用する．[`RadRotDirBlur_S()`](#radrotdirblur_s-関数) の中核関数で，引数の範囲チェックや画像サイズの領域拡張などは行わない．

|引数・戻り値|名前|型|説明|
|---:|:---:|:---:|:---|
|引数 \#1|`scale1`|number|移動元の拡大率，正数で指定，等倍は `1.0`.|
|引数 \#2|`rotate1`|number|移動元の回転角，ラジアン単位，時計回りに正．|
|引数 \#3|`move_x1`|number|移動元の X 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#4|`move_y1`|number|移動元の Y 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#5|`scale2`|number|移動先の拡大率，正数で指定，等倍は `1.0`.|
|引数 \#6|`rotate2`|number|移動先の回転角，ラジアン単位，時計回りに正．|
|引数 \#7|`move_x2`|number|移動先の X 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#8|`move_y2`|number|移動先の Y 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#9|`center_x`|number|拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点，右に正．|
|引数 \#10|`center_y`|number|拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点，下に正．|
|引数 \#11|`quality`|integer|1 ピクセルを計算するのに利用されるピクセル数．最小は `2`.|
|引数 \#12|`reload`|boolean\|nil|GLShaderKit に対してシェーダーファイルの再読み込みを促す．デバッグ用．省略時は `false` と同等．|
|戻り値|||なし|

このブラー効果の中核となる関数です．[`.RadRotDirBlur_S()` 関数](#radrotdirblur_s-関数)から間接的に呼び出されます．直接呼び出すほうがパラメタの自由度が広く，理論上はできることが多いです．

```lua
RadRotDirBlur_S.rad_rot_dir_blur(scale1, rotate1, move_x1, move_y1, scale2, rotate2, move_x2, move_y2, center_x, center_y, quality, reload);
```

### `.calc_extra_size()` 関数

拡大率・回転角・座標位置の移動元・移動先を指定し，その変化に沿ったブラーを適用する場合での，必要な画像拡大幅を計算する．この関数では実際には領域拡張は行わないし，最大画像サイズは考慮しない．[`RadRotDirBlur_S()`](#radrotdirblur_s-関数) 内で `keep_size` が `false` の場合に利用される．

|引数・戻り値|名前|型|説明|
|---:|:---:|:---:|:---|
|引数 \#1|`width`|integer|現在の画像の横幅，ピクセル単位．|
|引数 \#2|`height`|integer|現在の画像の縦の高さ，ピクセル単位．|
|引数 \#3|`scale1`|number|移動元の拡大率，正数で指定，等倍は `1.0`.|
|引数 \#4|`rotate1`|number|移動元の回転角，ラジアン単位，時計回りに正．|
|引数 \#5|`move_x1`|number|移動元の X 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#6|`move_y1`|number|移動元の Y 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#7|`scale2`|number|移動先の拡大率，正数で指定，等倍は `1.0`.|
|引数 \#8|`rotate2`|number|移動先の回転角，ラジアン単位，時計回りに正．|
|引数 \#9|`move_x2`|number|移動先の X 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#10|`move_y2`|number|移動先の Y 座標の移動量，ピクセル単位，正で右方向．|
|引数 \#11|`center_x`|number|拡大や回転の中心の X 座標，ピクセル単位，画像の中央が原点，右に正．|
|引数 \#12|`center_y`|number|拡大や回転の中心の Y 座標，ピクセル単位，画像の中央が原点，下に正．|
|戻り値 \#1|`left`|integer|左方向の必要拡大量，0 以上の整数でピクセル単位．|
|戻り値 \#2|`top`|integer|上方向の必要拡大量，0 以上の整数でピクセル単位．|
|戻り値 \#3|`right`|integer|右方向の必要拡大量，0 以上の整数でピクセル単位．|
|戻り値 \#4|`bottom`|integer|下方向の必要拡大量，0 以上の整数でピクセル単位．|

必要サイズの事前計算に利用できます．戻り値はそのまま `obj.effect("領域拡張",...)` のパラメタとして渡せます．

```lua
local left, top, right, bottom = RadRotDirBlur_S.calc_extra_size(width, height, scale1, rotate1, move_x1, move_y1, scale2, rotate2, move_x2, move_y2, center_x, center_y);
obj.effect("領域拡張","上", top, "下", bottom, "左", left, "右", right);
```


##  TIPS

1.  [`拡大率`](#拡大率) と [`回転角`](#拡大率) を同時に指定すると螺旋ブラーになります．

1.  テキストエディタで `RadRotDirBlur_S.anm`, `RadRotDirBlur_S.lua`, `RadRotDirBlur_S.frag` を開くと冒頭付近にファイルバージョンが付記されています．

    ```lua
    --
    -- VERSION: v1.10
    --
    ```

    ファイル間でバージョンが異なる場合，更新漏れの可能性があるためご確認ください．

1.  「特定の1ピクセルが影響を及ぼす範囲」は概ね次の式で表される軌跡をたどった部分になります ([`相対位置`](#相対位置) が `0` の場合):

$$
\left[-\tfrac{1}{2}, +\tfrac{1}{2}\right] \ni t \mapsto r^t
\begin{pmatrix} \cos t\theta & \sin t\theta \\
-\sin t\theta & \cos t\theta \end{pmatrix}
p + t d \in \mathbb{R}^2
$$

ここに  $p$ は「特定の1ピクセル」の位置， $r$ は [`拡大率`](#拡大率) で指定した拡大率， $\theta$ は[`回転角`](#回転角) で指定した角度， $d$ は [`移動方向`](#移動方向) で指定した方向．


##  謝辞

このスクリプトの作成には Mr-Ojii 様の [RotBlur_M](https://github.com/Mr-Ojii/AviUtl-RotBlur_M-Script) や [DirBlur_M](https://github.com/Mr-Ojii/AviUtl-DirBlur_M-Script) を大いに参考にさせていただきました．この場で恐縮ですが感謝申し上げます．


## 改版履歴

- **v1.10** (2025-04-15)

  - 外部スクリプト用 API を 2 つ追加で開放．

  - コード整理．

- **v1.01** (2025-04-14)

  - `サイズ固定` が OFF のとき，上下左右最低1ピクセルはサイズが増えるよう変更．
    - 画像外側の透明領域を計算元データとして取り入れるため．
    - `強さ` が `0` など一切ぼかし効果のかからない場合を除く．

  - 最大画像サイズに配慮するように修正．

  - コード整理．

- **v1.00** (2025-04-13)

  - 初版．


## ライセンス

このプログラムの利用・改変・再頒布等に関しては MIT ライセンスに従うものとします．

---

The MIT License (MIT)

Copyright (C) 2025 sigma-axis

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

https://mit-license.org/


#  連絡・バグ報告

- GitHub: https://github.com/sigma-axis
- Twitter: https://x.com/sigma_axis
- nicovideo: https://www.nicovideo.jp/user/51492481
- Misskey.io: https://misskey.io/@sigma_axis
- Bluesky: https://bsky.app/profile/sigma-axis.bsky.social
