import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';

abstract interface class ProductRepository {
  Future<PageResult<Product>> find(ProductQuery query);

  Future<List<Product>> all();

  Future<Product?> findById(int id);

  Future<int> countLinked({int? brandId, int? categoryId, int? disciplineId});

  Future<bool> isSkuTaken(String sku, {int? exceptId});

  Future<Product> create(Product product);

  Future<Product> update(Product product);

  Future<void> softDelete(int id);

  Future<void> hardDelete(int id);

  Future<void> restore(int id);

  Future<int> deleteMany(List<int> ids);
}
