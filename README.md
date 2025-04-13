# RadRotDirBlur_S AviUtl スクリプト

放射ブラー (radial blur), 回転ブラー (rotation blur), 方向ブラー (directional blur) の 3 つを複合したぼかし効果を適用する AviUtl スクリプトです．

[ダウンロードはこちら．](https://github.com/sigma-axis/aviutl_RadRotDirBlur_S/releases) [紹介動画．](https://www.nicovideo.jp/watch/sm44874159)

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


## TIPS

1.  [`拡大率`](#拡大率) と [`回転角`](#拡大率) を同時に指定すると螺旋ブラーになります．

1.  「特定の1ピクセルが影響を及ぼす範囲」は概ね次の式で表される軌跡をたどった部分になります ([`相対位置`](#相対位置) が `0` の場合):

    $$
    \left[-\tfrac{1}{2}, +\tfrac{1}{2}\right] \ni t \mapsto r^t \begin{pmatrix}\cos t\theta & \sin t\theta \\ -\sin t\theta & \cos t\theta \end{pmatrix} p + t d \in \R^2
    $$

    ここに $p$ は「特定の1ピクセル」の位置，$r$ は [`拡大率`](#拡大率) で指定した拡大率，$\theta$ は[`回転角`](#回転角) で指定した角度，$d$ は [`移動方向`](#移動方向) で指定した方向．

1.  テキストエディタで `RadRotDirBlur_S.anm`, `RadRotDirBlur_S.lua`, `RadRotDirBlur_S.frag` を開くと冒頭付近にファイルバージョンが付記されています．

    ```lua
    --
    -- VERSION: v1.00
    --
    ```

    ファイル間でバージョンが異なる場合，更新漏れの可能性があるためご確認ください．


##  謝辞

このスクリプトの作成には Mr-Ojii 様の [RotBlur_M](https://github.com/Mr-Ojii/AviUtl-RotBlur_M-Script) や [DirBlur_M](https://github.com/Mr-Ojii/AviUtl-DirBlur_M-Script) を大いに参考にさせていただきました．この場で恐縮ですが感謝申し上げます．


## 改版履歴

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
