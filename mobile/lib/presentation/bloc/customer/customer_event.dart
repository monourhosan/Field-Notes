import 'package:equatable/equatable.dart';

abstract class CustomerEvent extends Equatable {
  const CustomerEvent();
  @override
  List<Object?> get props => [];
}

class LoadCustomers extends CustomerEvent {
  final bool reset;
  const LoadCustomers({this.reset = false});
  @override
  List<Object?> get props => [reset];
}

class CreateCustomerEvent extends CustomerEvent {
  final String name;
  final String? contactInformation;
  const CreateCustomerEvent({required this.name, this.contactInformation});
  @override
  List<Object?> get props => [name, contactInformation];
}

class UpdateCustomerEvent extends CustomerEvent {
  final String id;
  final String name;
  final String? contactInformation;
  const UpdateCustomerEvent({
    required this.id,
    required this.name,
    this.contactInformation,
  });
  @override
  List<Object?> get props => [id, name, contactInformation];
}

class DeleteCustomerEvent extends CustomerEvent {
  final String id;
  const DeleteCustomerEvent(this.id);
  @override
  List<Object?> get props => [id];
}
