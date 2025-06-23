// ファイル名: model_tvcm.stan
// 説明: 時変係数モデル

data {
  int T;        // データ取得期間の長さ
  vector[T] ex; // 説明変数
  vector[T] y;  // 観測値
}

parameters {
  vector[T] mu;       // 水準成分（時変の切片）
  vector[T] b;        // 時変係数
  real<lower=0> s_w;  // 水準成分の過程誤差の標準偏差
  real<lower=0> s_t;  // 時変係数の過程誤差の標準偏差
  real<lower=0> s_v;  // 観測誤差の標準偏差
}

transformed parameters {
  vector[T] alpha;        // 状態推定値 (mu + b*ex)
  
  for(i in 1:T) {
    alpha[i] = mu[i] + b[i] * ex[i];
  }
}

model {
  // 状態方程式 (各パラメータが時間でどう変化するか)
  for(i in 2:T) {
    mu[i] ~ normal(mu[i-1], s_w); // ランダムウォーク
    b[i] ~ normal(b[i-1], s_t);  // ランダムウォーク
  }
  
  // 観測方程式 (観測値yがどう得られるか)
  for(i in 1:T) {
    y[i] ~ normal(alpha[i], s_v);
  }
}
