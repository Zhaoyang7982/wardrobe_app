import '../models/clothing.dart';

/// 衣橱列表排序方式
enum WardrobeSortMode {
  /// 按本地 Isar 自增 id 从新到旧（近似「最近添加」）
  recentAdded,

  /// 按穿着次数降序
  mostWorn,

  /// 按购买日期降序（无购买日期的排在后）
  purchaseDate,
}

/// 衣物数据访问抽象（由 data 层实现）
abstract class ClothingRepository {
  /// 获取全部衣物
  Future<List<Clothing>> getAll();

  /// 按业务 id 查询，不存在则返回 null
  Future<Clothing?> getById(String id);

  /// 新增或更新
  Future<void> save(Clothing clothing);

  /// 按业务 id 删除
  Future<void> delete(String id);

  /// 关键词搜索（名称、品牌、标签等由实现决定匹配范围）
  Future<List<Clothing>> search(String keyword);

  /// 按条件筛选；未传入的参数不参与过滤
  Future<List<Clothing>> filterBy({
    String? category,
    String? color,
    String? season,
    String? occasion,
  });

  /// 衣橱列表：横向 Chip 类别、搜索词、筛选面板多选、排序
  Future<List<Clothing>> listForWardrobe({
    String? quickCategory,
    String? keyword,
    Set<String> panelCategories = const {},
    Set<String> panelColors = const {},
    Set<String> panelSeasons = const {},
    Set<String> panelOccasions = const {},
    Set<String> panelStyles = const {},
    WardrobeSortMode sort = WardrobeSortMode.recentAdded,
  });
}
