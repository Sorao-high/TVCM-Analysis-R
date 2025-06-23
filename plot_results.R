# ファイル名: plot_results.R
# 役割: 保存されたモデル推定結果を読み込み、可視化する

# ---- 設定の読み込み ----
# プロジェクトの設定はすべて config.R で管理
source("config.R")

# ---- パッケージの読み込み ----
library(rstan)
library(gridExtra)

# ---- 作図用関数の読み込み ----
source("plot_ssm_functions.R")


# ---- データの読み込み ----
# 表示するのは「ファイル名が格納された変数」である INPUT_RDS_FILE
cat("推定結果", OUTPUT_RDS_FILE, "を読み込みます...\n") # ← 正しい変数名に修正

# 保存したstanfitオブジェクトを読み込む
# ここで読み込んだ結果が fit というオブジェクトに格納される
fit <- readRDS(OUTPUT_RDS_FILE)
mcmc_sample <- rstan::extract(fit)

original_df <- readr::read_csv(CSV_FILE_PATH, col_types = cols())

if (!is.null(TIME_COL_NAME) && TIME_COL_NAME %in% names(original_df)) {
  time_vec <- original_df[[TIME_COL_NAME]]
} else {
  time_vec <- 1:nrow(original_df)
}
obs_vec <- original_df[[Y_COL_NAME]]


# ---- グラフの作成 ----
cat("グラフを作成しています...\n")
p_alpha <- plot_ssm_state(mcmc_sample, time_vec, obs_vec,
                          state_name = "alpha",
                          graph_title = "Overall State (alpha) vs Observations",
                          y_label = "Value (y)")

p_mu <- plot_ssm_state(mcmc_sample, time_vec,
                       state_name = "mu",
                       graph_title = "Time-Varying Intercept (mu)",
                       y_label = "Intercept")

p_b <- plot_ssm_state(mcmc_sample, time_vec,
                      state_name = "b",
                      graph_title = "Time-Varying Coefficient (b)",
                      y_label = "Coefficient")


# ---- グラフの結合と保存 ----
plot_combined <- grid.arrange(p_alpha, p_mu, p_b, ncol = 1)

ggsave(
  filename = PLOT_OUTPUT_FILE,
  plot = plot_combined,
  width = PLOT_WIDTH,
  height = PLOT_HEIGHT,
  dpi = PLOT_DPI
)

cat("グラフを", PLOT_OUTPUT_FILE, "に保存しました。\n")

