import '../entities/site.dart';

abstract class SiteRepository {
  Future<List<Site>> getSites({String? customerId});
  Future<Site?> getSiteById(String id);
  Future<Site> createSite({required String customerId, required String siteName, String? address});
  Future<Site> updateSite({required String id, required String customerId, required String siteName, String? address});
  Future<void> deleteSite(String id);
}
