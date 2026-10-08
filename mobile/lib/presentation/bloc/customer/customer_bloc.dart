import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/repositories/customer_repository.dart';
import 'customer_event.dart';
import 'customer_state.dart';

class CustomerBloc extends Bloc<CustomerEvent, CustomerState> {
  final CustomerRepository _customerRepository;

  CustomerBloc(this._customerRepository) : super(CustomerInitial()) {
    on<LoadCustomers>(_onLoadCustomers, transformer: restartable());
    on<CreateCustomerEvent>(_onCreateCustomer, transformer: sequential());
    on<UpdateCustomerEvent>(_onUpdateCustomer, transformer: sequential());
    on<DeleteCustomerEvent>(_onDeleteCustomer, transformer: sequential());
  }

  Future<void> _onLoadCustomers(
    LoadCustomers event,
    Emitter<CustomerState> emit,
  ) async {
    if (event.reset) {
      emit(CustomerInitial());
      return;
    }
    emit(CustomerLoading());
    try {
      final customers = await _customerRepository.getCustomers();
      emit(CustomerLoaded(customers));
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateCustomer(
    CreateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _customerRepository.createCustomer(
        name: event.name,
        contactInformation: event.contactInformation,
      );
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCustomer(
    UpdateCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _customerRepository.updateCustomer(
        id: event.id,
        name: event.name,
        contactInformation: event.contactInformation,
      );
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteCustomer(
    DeleteCustomerEvent event,
    Emitter<CustomerState> emit,
  ) async {
    try {
      await _customerRepository.deleteCustomer(event.id);
      add(LoadCustomers());
    } catch (e) {
      emit(CustomerError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
