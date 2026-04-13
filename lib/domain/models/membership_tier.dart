/// 会员档位：决定抠图走云端 API 还是端上 TFLite（见产品策略）
enum MembershipTier {
  /// 默认：端上本地模型（零 remove.bg 调用）
  free,

  /// 云端 remove.bg 高精度抠图
  vip,
}
