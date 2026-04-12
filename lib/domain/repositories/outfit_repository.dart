import '../models/outfit.dart';

/// 搭配数据访问抽象（由 data 层实现）
abstract class OutfitRepository {
  /// 获取「搭配」页等使用的列表（不含已归档）
  Future<List<Outfit>> getAll();

  /// 含已归档；用于日历、统计穿着记录、离线缓存全量同步等
  Future<List<Outfit>> getAllIncludingArchived();

  /// 按业务 id 查询，不存在则返回 null
  Future<Outfit?> getById(String id);

  /// 新增或更新
  Future<void> save(Outfit outfit);

  /// 按业务 id 删除：若 [Outfit.wornDates] 非空则进入回收站（归档），否则永久删除。
  Future<void> delete(String id);

  /// 从回收站或本地彻底删除（不可恢复）
  Future<void> permanentlyDelete(String id);

  /// 某日已穿或计划穿的搭配（实现中按 wornDates / plannedDates 与 [date] 的日期部分匹配）
  Future<List<Outfit>> getByDate(DateTime date);

  /// 包含指定衣物 id 的搭配列表
  Future<List<Outfit>> listContainingClothing(String clothingId);
}
