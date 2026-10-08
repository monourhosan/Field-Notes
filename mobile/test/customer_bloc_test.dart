import 'package:flutter_test/flutter_test.dart';
import 'package:field_notes_app/domain/entities/customer.dart';
import 'package:field_notes_app/domain/entities/sync_status.dart';
import 'package:field_notes_app/domain/repositories/customer_repository.dart';
import 'package:field_notes_app/presentation/bloc/customer/customer_bloc.dart';
import 'package:field_notes_app/presentation/bloc/customer/customer_event.dart';
import 'package:field_notes_app/presentation/bloc/customer/customer_state.dart';

class MockCustomerRepository implements CustomerRepository {
  List<Customer> customers = [];

  @override
  Future<List<Customer>> getCustomers() async => customers;

  @override
  Future<Customer?> getCustomerById(String id) async {
    try {
      return customers.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Customer> createCustomer({
    required String name,
    String? contactInformation,
  }) async {
    final newCust = Customer(
      id: 'cust-1',
      userId: 1,
      name: name,
      contactInformation: contactInformation,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      syncStatus: SyncStatus.synced,
    );
    customers.add(newCust);
    return newCust;
  }

  @override
  Future<Customer> updateCustomer({
    required String id,
    required String name,
    String? contactInformation,
  }) async {
    final index = customers.indexWhere((c) => c.id == id);
    final updated = customers[index].copyWith(
      name: name,
      contactInformation: contactInformation,
    );
    customers[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteCustomer(String id) async {
    customers.removeWhere((c) => c.id == id);
  }
}

void main() {
  group('CustomerBloc', () {
    late CustomerBloc bloc;
    late MockCustomerRepository repository;

    setUp(() {
      repository = MockCustomerRepository();
      bloc = CustomerBloc(repository);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is CustomerInitial', () {
      expect(bloc.state, equals(CustomerInitial()));
    });

    test(
      'emits [CustomerLoading, CustomerLoaded] when LoadCustomers is added',
      () async {
        repository.customers = [
          Customer(
            id: '1',
            userId: 1,
            name: 'Apex Industries',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        expectLater(
          bloc.stream,
          emitsInOrder([
            isA<CustomerLoading>(),
            isA<CustomerLoaded>().having(
              (s) => s.customers.length,
              'length',
              1,
            ),
          ]),
        );

        bloc.add(LoadCustomers());
      },
    );

    test('creates customer and refreshes list', () async {
      bloc.add(
        const CreateCustomerEvent(
          name: 'New Client Ltd',
          contactInformation: 'contact@client.com',
        ),
      );

      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<CustomerLoaded>().having(
            (s) => s.customers.any((c) => c.name == 'New Client Ltd'),
            'has client',
            true,
          ),
        ),
      );
    });
  });
}
