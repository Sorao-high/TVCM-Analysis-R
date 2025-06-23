# TVCM-Analysis-R
An R script collection for Time-Varying Coefficient Model analysis using Bayesian estimation with Stan.

このリポジトリは、時変係数モデル（Time-Varying Coefficient Model）をベイズ推定するためのRスクリプト群です。
コマンドラインベースで分析を実行し、説明変数が目的変数に与える影響が時間とともにどう変化したかを推定・可視化することができます。また、補足として、これらの分析をブラウザ上で実行できるShinyアプリケーションも同梱しています。
✨ 特徴
再現性の高い分析: config.Rで設定を一元管理し、誰でも同じ分析を再現できます。
動的な関係性の可視化: 固定的な係数を仮定する通常の回帰分析とは異なり、「広告効果が時間とともに薄れていく」といった係数の動的な変化を捉えることができます。
ベイズ推定: 統計モデリングフレームワーク Stan を用いて、不確実性を考慮した堅牢なベイズ推定を行います。
柔軟なワークフロー: 時間のかかるモデル推定（run_model.R）と、素早く試行錯誤したい結果の可視化（plot_results.R）のプロセスを分離しています。
🔧 必要な環境とパッケージ
このスクリプトを実行するには、RおよびRStudioがインストールされている必要があります。
また、以下のRパッケージが必要です。
Generated R
# 以下のコマンドをRコンソールで実行して、必要なパッケージをインストールしてください
install.packages(c(
  "rstan", 
  "tidyverse", 
  "lubridate", 
  "gridExtra"
))
Use code with caution.
R
重要: rstanの実行には、C++コンパイラが必要です。
Windows: Rtoolsをインストールしてください。
Mac: Xcode Command Line Toolsをインストールしてください (xcode-select --installをターミナルで実行)。
🚀 使い方 (コマンドライン)
分析は以下の3ステップで実行します。
Step 1: 設定ファイルの編集
config.R ファイルを開き、分析内容に合わせて設定を編集します。
入力ファイルと列名: CSV_FILE_PATH, Y_COL_NAME, EX_COL_NAME, TIME_COL_NAME を、ご自身のデータに合わせて変更します。
MCMCの設定: ITER や WARMUP などのパラメータを必要に応じて調整します。
出力ファイル名: 結果の保存先ファイル名を指定します。
Step 2: モデルの推定
RStudioのコンソールで、以下のコマンドを実行します。
これにより、config.R の設定に基づいてStanによるMCMCサンプリングが開始されます。この処理は時間がかかる場合があります。
Generated R
source("run_model.R")
Use code with caution.
R
処理が完了すると、推定結果（stanfitオブジェクト）が config.R で指定した .rds ファイルに保存されます。
Step 3: 結果の可視化
モデルの推定が終わったら、以下のコマンドで結果をプロットします。
Generated R
source("plot_results.R")
Use code with caution.
R
plot_results.R は、Step 2で保存された .rds ファイルを読み込み、分析結果のグラフを生成して .png ファイルとして保存します。グラフの見た目（色、タイトルなど）を調整したい場合は、このファイルを編集して何度でも素早く実行できます。
📁 ファイル構成
Generated code
.
├── config.R               # ★ 分析の全体設定を行うファイル
├── run_model.R            # ★ モデル推定を実行するスクリプト
├── plot_results.R         # ★ 推定結果を可視化するスクリプト
│
├── model_tvcm.stan        # Stanで記述された時変係数モデル
├── plot_ssm_functions.R   # 作図用の補助関数
│
├── sample_sales_data.csv  # 動作確認用のサンプルデータ
├── generate_test_data.R   # サンプルデータ生成用のスクリプト
│
├── app.R                  # (補足) Shinyアプリケーション
│
└──  README.md              # このファイル

Use code with caution.
✨ (補足) Shiny Webアプリケーション
このリポジトリには、上記の分析をWebブラウザ上でインタラクティブに実行できるShinyアプリケーション (app.R) も同梱されています。
起動方法
コマンドライン版と同様に必要なパッケージをインストールします。（shiny, shinycssloaders, shinybusyが追加で必要です）
RStudioで app.R を開き、エディタ右上の "Run App" ボタンをクリックします。
⚠️ 注意事項
このShinyアプリケーションは、内部でリソースを大量に消費する rstan を実行します。お使いのPCの環境（メモリ搭載量、OS、パッケージのバージョンなど）によっては、Rセッションが予期せずクラッシュする（"R Session Aborted"）可能性があります。
もしクラッシュが頻発する場合は、安定して動作するコマンドライン版（run_model.R と plot_results.R）のご利用を推奨します。
