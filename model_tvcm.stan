// �t�@�C����: model_tvcm.stan
// ����: ���όW�����f��

data {
  int T;        // �f�[�^�擾���Ԃ̒���
  vector[T] ex; // �����ϐ�
  vector[T] y;  // �ϑ��l
}

parameters {
  vector[T] mu;       // ���������i���ς̐ؕЁj
  vector[T] b;        // ���όW��
  real<lower=0> s_w;  // ���������̉ߒ��덷�̕W���΍�
  real<lower=0> s_t;  // ���όW���̉ߒ��덷�̕W���΍�
  real<lower=0> s_v;  // �ϑ��덷�̕W���΍�
}

transformed parameters {
  vector[T] alpha;        // ��Ԑ���l (mu + b*ex)
  
  for(i in 1:T) {
    alpha[i] = mu[i] + b[i] * ex[i];
  }
}

model {
  // ��ԕ����� (�e�p�����[�^�����Ԃłǂ��ω����邩)
  for(i in 2:T) {
    mu[i] ~ normal(mu[i-1], s_w); // �����_���E�H�[�N
    b[i] ~ normal(b[i-1], s_t);  // �����_���E�H�[�N
  }
  
  // �ϑ������� (�ϑ��ly���ǂ������邩)
  for(i in 1:T) {
    y[i] ~ normal(alpha[i], s_v);
  }
}
