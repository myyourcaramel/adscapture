# silence_remover

`silence_remover.ps1` は、動画ファイルから無音部分を自動的に検出し、削除するスクリプトです。

## 前提条件

- Windows
- FFmpeg がインストールされていること
- PowerShell 実行環境

## FFmpegのインストール方法

- [FFmpeg公式サイト](https://ffmpeg.org/download.html)からFFmpegをダウンロード
- ダウンロードしたzipファイルを解凍
- 解凍したフォルダ内の`bin`フォルダを環境変数PATHに追加

## 使用方法

- 処理したい動画ファイルを`in.mp4`という名前でスクリプトと同じフォルダに配置
- PowerShell起動
- スクリプトのあるフォルダに移動
- 以下のコマンドでスクリプトの実行を許可：
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```
- スクリプトを実行：
```powershell
.\silence_remover.ps1
```

## 出力ファイル

- `outall.mp4`: 無音部分が削除され、音声が正規化された最終出力ファイル
- その他の中間ファイル：
  - `spec.txt`: 無音検出結果
  - `start.txt`, `end.txt`: 無音部分の開始・終了時間
  - `out{n}.mp4`: 処理の中間ファイル

## パラメータ設定

スクリプト内の以下のパラメータを必要に応じて調整可能：

- `$initial_db = -60`: 無音検出の初期しきい値(dB)
- `$db_step = 5`: 無音検出の調整ステップ(dB)
- `$max_attempts = 4`: 無音検出の最大試行回数
- `d=0.4`: 無音と判定する最小の継続時間(秒)
- `$bin_arr_length = 100`: 一度に処理する無音区間の数

スクリプトは自動的に最適な無音検出しきい値を見つけようとします。初期値の-60dBから開始し、無音区間が見つからない場合は徐々にしきい値を上げていきます。
