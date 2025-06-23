# ファイル名: run_model.R
# 役割: 時変係数モデルのMCMCサンプリングを実行し、結果を保存する

# ---- 設定の読み込み ----
# プロジェクトの設定はすべて config.R で管理
source("config.R")

# ---- パッケージの読み込み ----
library(rstan)

# ---- 計算の高速化 ----
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())


# ---- データの読み込みと準備 ----
cat("データの読み込みを開始します...\n")

original_df <- readr::read_csv(CSV_FILE_PATH, col_types = cols())

data_list <- list(
  y = original_df[[Y_COL_NAME]], 
  ex = original_df[[EX_COL_NAME]], 
  T = nrow(original_df)
)

# ---- モデルの推定 ----
cat("モデルの推定を開始します（時間がかかる場合があります）...\n")

fit <- stan(
  file = STAN_MODEL_FILE,
  data = data_list,
  seed = SEED,
  chains = CHAINS,
  iter = ITER,
  warmup = WARMUP,
  thin = THIN
)

# ---- 結果の保存 ----
cat("推定結果を", OUTPUT_RDS_FILE, "に保存します...\n")
saveRDS(object = fit, file = OUTPUT_RDS_FILE)

cat("処理が完了しました。\n")

# ---- (参考) 収束の確認 ----
print(fit, pars = c("s_w", "s_t", "s_v"))
check_hmc_diagnostics(fit)

getwd()

