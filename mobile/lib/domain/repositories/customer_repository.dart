import '../entities/customer.dart';

abstract class CustomerRepository {
  Future<List<Customer>> getCustomers();
  Future<Customer?> getCustomerById(String id);
  Future<Customer> createCustomer({required String name, String? contactInformation});
  Future<Customer> updateCustomer({required String id, required String name, String? contactInformation});
  Future<void> deleteCustomer(String id);
}
