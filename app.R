# ファイル名: app.R
# 役割: 時変係数モデル分析のShinyアプリケーション

# ---- 必要なパッケージを読み込む ----
# アプリ起動前に、これらのパッケージがインストールされていることを確認してください
# install.packages(c("shiny", "rstan", "tidyverse", "lubridate", "gridExtra", "shinycssloaders", "rstudioapi"))
library(shiny)
library(shinybusy)
library(shinycssloaders)
library(tidyverse) # これを先に
library(rstan)     # rstanを後に
library(lubridate)
library(gridExtra)

# ---- Stanのオプション設定 ----
rstan_options(auto_write = TRUE)
#options(mc.cores = parallel::detectCores())

# ---- 外部ファイルを読み込む ----
source("plot_ssm_functions.R")
STAN_MODEL_FILE <- "model_tvcm.stan"


# ==============================================================================
# UI (ユーザーインターフェース) の定義
# ==============================================================================
ui <- fluidPage(
  
  # ★★★ shinybusyの機能を有効化するためのコードを追加 ★★★
  add_busy_spinner(spin = "fading-circle", position = "full-page"),
  
  # アプリのタイトル
  titlePanel("時変係数モデル 分析ツール"),
  
  # レイアウトの定義 (サイドバーとメインパネル)
  sidebarLayout(
    
    # ---- サイドバーパネル (入力コントロール) ----
    sidebarPanel(
      width = 3, # サイドバーの幅を調整
      h4("1. データファイルの準備"),
      # ファイルアップロード
      fileInput("csv_file", "CSVファイルをアップロード",
                accept = c("text/csv", ".csv")),
      
      hr(), # 区切り線
      
      h4("2. 列の割り当て"),
      # 以下のUIは、ファイルがアップロードされた後に動的に生成される
      uiOutput("y_col_ui"),
      uiOutput("ex_col_ui"),
      uiOutput("time_col_ui"),
      
      hr(),
      
      h4("3. MCMCの設定"),
      numericInput("chains", "チェイン数:", 1, min = 1),
      numericInput("iter", "イテレーション数:", 500, min = 100),
      numericInput("warmup", "ウォームアップ数:", 200, min = 50),
      numericInput("seed", "乱数シード:", 1),
      
      hr(),
      
      # 分析実行ボタン
      actionButton("run_analysis", "分析実行", icon = icon("play-circle"), class = "btn-primary btn-lg")
    ),
    
    # ---- メインパネル (出力表示) ----
    mainPanel(
      width = 9,
      tabsetPanel(
        type = "tabs",
        # 「結果のプロット」タブ
        tabPanel("結果のプロット", 
                 # 計算中はスピナー（くるくる回るアイコン）を表示
                 withSpinner(
                   plotOutput("result_plot", height = "800px"),
                   type = 6, # スピナーの見た目を変更
                   color = "#0dc5c1"
                 )
        ),
        # 「推定結果の要約」タブ
        tabPanel("推定結果の要約",
                 withSpinner(
                   verbatimTextOutput("summary_output"),
                   type = 6,
                   color = "#0dc5c1"
                 )
        ),
        # 「収束診断」タブ
        tabPanel("収束診断",
                 withSpinner(
                   plotOutput("trace_plot", height = "800px"),
                   type = 6,
                   color = "#0dc5c1"
                 )
        )
      )
    )
  )
)


# ==============================================================================
# Server (サーバーロジック) の定義
# ==============================================================================
server <- function(input, output, session) {
  
  # ---- リアクティブな値の管理 ----
  
  # アップロードされたCSVデータを格納するリアクティブなオブジェクト
  uploaded_data <- reactive({
    req(input$csv_file) # ファイルがアップロードされるまで待つ
    read_csv(input$csv_file$datapath)
  })
  
  # ---- 動的なUIの生成 ----
  
  # 目的変数(y)を選択するUIを生成
  output$y_col_ui <- renderUI({
    df <- uploaded_data()
    req(df)
    selectInput("y_col", "目的変数 (y):", choices = names(df))
  })
  
  # 説明変数(ex)を選択するUIを生成
  output$ex_col_ui <- renderUI({
    df <- uploaded_data()
    req(df)
    selectInput("ex_col", "説明変数 (ex):", choices = names(df), selected = names(df)[2])
  })
  
  # 時間軸の列を選択するUIを生成（"なし"も選択可能）
  output$time_col_ui <- renderUI({
    df <- uploaded_data()
    req(df)
    selectInput("time_col", "時間軸 (任意):", choices = c("インデックスを使用" = "none", names(df)))
  })
  
  
  # ---- モデルの実行と結果の生成 ----
  
  # "分析実行"ボタンが押されたときに、モデル推定を実行する
  # eventReactive を使うことで、ボタンが押された時だけ実行されるようにする
  model_fit <- eventReactive(input$run_analysis, {
    
    # ユーザー入力を確認
    req(uploaded_data(), input$y_col, input$ex_col)
    
    df <- uploaded_data()
    
    # Stanに渡すデータリストを準備
    data_list <- list(
      y = df[[input$y_col]],
      ex = df[[input$ex_col]],
      T = nrow(df)
    )
    
    # 計算中であることをユーザーに通知
    show_modal_spinner(
      spin = "fading-circle",
      color = "#0dc5c1",
      text = "MCMCサンプリングを実行中です。しばらくお待ちください..."
    )
    
    # StanによるMCMCサンプリングを実行
    fit <- stan(
      file = STAN_MODEL_FILE,
      data = data_list,
      seed = input$seed,
      chains = input$chains,
      iter = input$iter,
      warmup = input$warmup,
      cores = 1
    )
    
    # 通知を消す
    remove_modal_spinner()
    
    return(fit)
  })
  
  # ---- 出力のレンダリング ----
  
  # 1. 結果のプロットを生成
  output$result_plot <- renderPlot({
    fit <- model_fit() # モデル推定結果を取得
    
    df <- uploaded_data()
    
    # 時間軸ベクトルを準備
    if (input$time_col != "none") {
      time_vec <- df[[input$time_col]]
    } else {
      time_vec <- 1:nrow(df)
    }
    
    # MCMCサンプルを抽出
    mcmc_sample <- rstan::extract(fit)
    
    # 各プロットを作成
    p_alpha <- plot_ssm_state(mcmc_sample, time_vec, df[[input$y_col]],
                              "alpha", "Overall State (alpha) vs Observations", "Value (y)")
    
    p_mu <- plot_ssm_state(mcmc_sample, time_vec, NULL,
                           "mu", "Time-Varying Intercept (mu)", "Intercept")
    
    p_b <- plot_ssm_state(mcmc_sample, time_vec, NULL,
                          "b", "Time-Varying Coefficient (b)", "Coefficient")
    
    # グラフを結合して表示
    grid.arrange(p_alpha, p_mu, p_b, ncol = 1)
  })
  
  # 2. 推定結果の要約をテキストで表示
  output$summary_output <- renderPrint({
    fit <- model_fit()
    print(fit, pars = c("s_w", "s_t", "s_v"), probs = c(0.025, 0.5, 0.975))
  })
  
  # 3. 収束診断のためのトレースプロットを表示
  output$trace_plot <- renderPlot({
    fit <- model_fit()
    rstan::traceplot(fit, pars = c("s_w", "s_t", "s_v"), inc_warmup = TRUE)
  })
  
}

# ==============================================================================
# アプリの実行
# ==============================================================================
shinyApp(ui = ui, server = server)