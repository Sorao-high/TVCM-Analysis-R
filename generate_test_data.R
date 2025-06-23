# ファイル名: generate_test_data.R
# 役割: 時変係数モデルのテスト用サンプルデータを生成する

library(tidyverse)
library(lubridate) # 日付操作のため

# ---- 設定 ----
set.seed(123) # 再現性のための乱数シード
N_WEEKS <- 156 # データ期間（週単位、3年分）
OUTPUT_CSV_FILE <- "sample_sales_data.csv"

# ---- 1. 時間軸の作成 ----
start_date <- ymd("2021-01-01")
time_vec <- start_date + weeks(0:(N_WEEKS - 1))

# ---- 2. 隠れた状態（真の値）を生成 ----

# a) ベース売上（切片 mu）の真の動き
# 緩やかな上昇トレンド + 季節性
true_mu <- 100 +                                    # ベースライン
  seq(0, 50, length.out = N_WEEKS) +      # 上昇トレンド
  25 * sin(2 * pi * (1:N_WEEKS) / 52) +   # 夏のピーク（1年周期）
  15 * sin(2 * pi * (1:N_WEEKS) / 26)     # 冬のピーク（半年周期）

# b) 広告費 (説明変数 ex)
# 普段は低コスト、年に4回大規模キャンペーン
promotion <- rpois(N_WEEKS, lambda = 15) # 基本の広告費
campaign_weeks <- sample(1:N_WEEKS, size = 12) # 3年間で12回のキャンペーン
promotion[campaign_weeks] <- promotion[campaign_weeks] + rpois(12, lambda = 80)

# c) 広告効果（時変係数 b）の真の動き
# 最初は効果が高い(2.0)が、徐々に効果が薄れていく(0.5)
true_b <- seq(from = 2.0, to = 0.5, length.out = N_WEEKS) + 
  rnorm(N_WEEKS, mean = 0, sd = 0.1) # 少しノイズを加える

# ---- 3. 観測値（売上）を生成 ----
# 観測値 = (ベース売上) + (広告効果) * (広告費) + (ノイズ)
# 観測方程式: y[t] = mu[t] + b[t]*ex[t] + v[t]
observation_error_sd <- 15 # 観測ノイズの大きさ
sales <- true_mu + true_b * promotion + rnorm(N_WEEKS, 0, observation_error_sd)
# 売上は負にならないように調整
sales[sales < 0] <- 0

# ---- 4. データフレームにまとめてCSVで保存 ----
# Stanモデルで使う列名に合わせておく
test_data <- tibble(
  date = time_vec,
  sales = round(sales),     # 目的変数 (y)
  promotion = promotion,    # 説明変数 (ex)
  true_mu = true_mu,        # (参考) 真のmu
  true_b = true_b           # (参考) 真のb
)

# CSVファイルとして書き出す
write_csv(test_data, OUTPUT_CSV_FILE)

cat("テストデータを '", OUTPUT_CSV_FILE, "' に保存しました。\n", sep="")

# ---- (参考) 生成したデータの可視化 ----
# 全体の売上と広告費
p1 <- ggplot(test_data, aes(x = date)) +
  geom_line(aes(y = sales, color = "Sales"), alpha = 0.8) +
  geom_col(aes(y = promotion, fill = "Promotion"), alpha = 0.5) +
  scale_color_manual(name = "", values = c("Sales" = "black")) +
  scale_fill_manual(name = "", values = c("Promotion" = "skyblue")) +
  labs(title = "Generated Sales and Promotion Data", y = "Value") +
  theme_bw() +
  theme(legend.position = "top")

# 隠れた真の状態（モデルが推定すべきもの）
p2 <- ggplot(test_data, aes(x = date)) +
  geom_line(aes(y = true_mu, color = "True Intercept (mu)")) +
  geom_line(aes(y = true_b, color = "True Coefficient (b)"), linetype = "dashed") +
  scale_color_manual(name = "True State", values = c("True Intercept (mu)" = "blue", "True Coefficient (b)" = "red")) +
  labs(title = "True Underlying States (What the model should estimate)", y = "Value") +
  theme_bw() +
  theme(legend.position = "top")

# 2つのグラフを並べて表示
# gridExtra::grid.arrange(p1, p2, ncol = 1)
# print()で順番に表示
print(p1)
print(p2)