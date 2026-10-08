import 'package:equatable/equatable.dart';

import '../../../domain/entities/site.dart';

abstract class SiteState extends Equatable {
  const SiteState();
  @override
  List<Object?> get props => [];
}

class SiteInitial extends SiteState {}

class SiteLoading extends SiteState {}

class SiteLoaded extends SiteState {
  final List<Site> sites;
  const SiteLoaded(this.sites);
  @override
  List<Object?> get props => [sites];
}

class SiteError extends SiteState {
  final String message;
  const SiteError(this.message);
  @override
  List<Object?> get props => [message];
}
