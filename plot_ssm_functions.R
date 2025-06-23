# ファイル名: plot_ssm_functions.R
# 役割: 状態空間モデルの推定結果を可視化するための関数群

library(ggplot2)
library(dplyr)
library(tidyr)

#' 状態の時系列変化をプロットする関数
#'
#' @param mcmc_sample rstan::extract()で得られたMCMCサンプルのリスト
#' @param time_vec 時間軸のベクトル（日付またはインデックス）
#' @param obs_vec (任意) 観測値のベクトル。プロットに点で追加される
#' @param state_name プロットしたい状態の名前（"alpha", "mu", "b"など）
#' @param graph_title グラフのタイトル
#' @param y_label Y軸のラベル
#' @param prob 信用区間の幅 (例: 0.95 -> 95%信用区間)
#'
#' @return ggplotオブジェクト
plot_ssm_state <- function(mcmc_sample, time_vec, obs_vec = NULL,
                           state_name, graph_title, y_label, prob = 0.95) {
  
  # 信用区間の計算
  lower_p <- (1 - prob) / 2
  upper_p <- 1 - lower_p
  
  # MCMCサンプルから指定された状態のデータフレームを作成
  as.data.frame(mcmc_sample[[state_name]]) %>%
    # 各時点(列)のパーセンタイルを計算
    summarise(across(everything(),
                     list(
                       median = ~quantile(., probs = 0.5),
                       lower = ~quantile(., probs = lower_p),
                       upper = ~quantile(., probs = upper_p)
                     ),
                     .names = "{.col}_{.fn}")) %>% # 列名の形式を_で統一
    # ワイド形式からロング形式へ変換
    pivot_longer(cols = everything(),
                 names_to = c(".value"), # .valueのみ指定
                 names_pattern = "V[0-9]+_(.*)") %>% # ★★★ バグ修正箇所 ★★★
    # 時間軸を追加
    mutate(time = time_vec) -> state_df
  
  # グラフの作成
  p <- ggplot(state_df, aes(x = time)) +
    geom_ribbon(aes(ymin = lower, ymax = upper), fill = "skyblue", alpha = 0.4) +
    geom_line(aes(y = median), color = "dodgerblue", linewidth = 1) +
    labs(title = graph_title, x = "Time", y = y_label) +
    theme_bw(base_size = 15) +
    theme(axis.title.x = element_blank())
  
  # 観測値があればプロットに追加
  if (!is.null(obs_vec)) {
    obs_df <- data.frame(time = time_vec, obs = obs_vec)
    p <- p + geom_point(data = obs_df, aes(x = time, y = obs),
                        color = "gray40", alpha = 0.6, size = 1.5)
  }
  
  return(p)
}