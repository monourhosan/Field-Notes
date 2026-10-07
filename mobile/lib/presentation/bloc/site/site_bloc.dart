import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/site_repository.dart';
import 'site_event.dart';
import 'site_state.dart';

class SiteBloc extends Bloc<SiteEvent, SiteState> {
  final SiteRepository _siteRepository;

  SiteBloc(this._siteRepository) : super(SiteInitial()) {
    on<LoadSites>(_onLoadSites);
    on<CreateSiteEvent>(_onCreateSite);
    on<UpdateSiteEvent>(_onUpdateSite);
    on<DeleteSiteEvent>(_onDeleteSite);
  }

  Future<void> _onLoadSites(LoadSites event, Emitter<SiteState> emit) async {
    emit(SiteLoading());
    try {
      final sites = await _siteRepository.getSites(customerId: event.customerId);
      emit(SiteLoaded(sites));
    } catch (e) {
      emit(SiteError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCreateSite(CreateSiteEvent event, Emitter<SiteState> emit) async {
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

  Future<void> _onUpdateSite(UpdateSiteEvent event, Emitter<SiteState> emit) async {
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

  Future<void> _onDeleteSite(DeleteSiteEvent event, Emitter<SiteState> emit) async {
    try {
      await _siteRepository.deleteSite(event.id);
      add(LoadSites(customerId: event.customerId));
    } catch (e) {
      emit(SiteError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
