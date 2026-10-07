import 'package:equatable/equatable.dart';

abstract class SiteEvent extends Equatable {
  const SiteEvent();
  @override
  List<Object?> get props => [];
}

class LoadSites extends SiteEvent {
  final String? customerId;
  const LoadSites({this.customerId});
  @override
  List<Object?> get props => [customerId];
}

class CreateSiteEvent extends SiteEvent {
  final String customerId;
  final String siteName;
  final String? address;
  const CreateSiteEvent({required this.customerId, required this.siteName, this.address});
  @override
  List<Object?> get props => [customerId, siteName, address];
}

class UpdateSiteEvent extends SiteEvent {
  final String id;
  final String customerId;
  final String siteName;
  final String? address;
  const UpdateSiteEvent({required this.id, required this.customerId, required this.siteName, this.address});
  @override
  List<Object?> get props => [id, customerId, siteName, address];
}

class DeleteSiteEvent extends SiteEvent {
  final String id;
  final String? customerId;
  const DeleteSiteEvent(this.id, {this.customerId});
  @override
  List<Object?> get props => [id, customerId];
}
