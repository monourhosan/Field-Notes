import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';

import '../../../domain/repositories/site_repository.dart';
import 'site_event.dart';
import 'site_state.dart';

class SiteBloc extends Bloc<SiteEvent, SiteState> {
  final SiteRepository _siteRepository;
  LoadSites _lastLoad = const LoadSites();

  SiteBloc(this._siteRepository) : super(SiteInitial()) {
    on<LoadSites>(_onLoadSites, transformer: restartable());
    on<RefreshSites>((event, emit) => add(_lastLoad));
    on<CreateSiteEvent>(_onCreateSite, transformer: sequential());
    on<UpdateSiteEvent>(_onUpdateSite, transformer: sequential());
    on<DeleteSiteEvent>(_onDeleteSite, transformer: sequential());
  }

  Future<void> _onLoadSites(LoadSites event, Emitter<SiteState> emit) async {
    if (event.reset) {
      _lastLoad = const LoadSites();
      emit(SiteInitial());
      return;
    }
    _lastLoad = event;
    emit(SiteLoading());
    try {
      final sites = await _siteRepository.getSites(
        customerId: event.customerId,
      );
      emit(SiteLoaded(sites));
    } catch (e) {
      emit(SiteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSite(
    CreateSiteEvent event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await _siteRepository.createSite(
        customerId: event.customerId,
        siteName: event.siteName,
        address: event.address,
      );
      add(LoadSites(customerId: event.customerId));
    } catch (e) {
      emit(SiteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateSite(
    UpdateSiteEvent event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await _siteRepository.updateSite(
        id: event.id,
        customerId: event.customerId,
        siteName: event.siteName,
        address: event.address,
      );
      add(LoadSites(customerId: event.customerId));
    } catch (e) {
      emit(SiteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onDeleteSite(
    DeleteSiteEvent event,
    Emitter<SiteState> emit,
  ) async {
    try {
      await _siteRepository.deleteSite(event.id);
      add(LoadSites(customerId: event.customerId));
    } catch (e) {
      emit(SiteError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
