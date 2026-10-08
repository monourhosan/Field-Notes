import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/local/database_helper.dart';
import '../../data/local/settings_local_data_source.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/note/field_note_bloc.dart';
import '../bloc/note/field_note_event.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../bloc/sync/sync_state.dart';

// Sync while active, on login, on connectivity changes, and after local mutations.
// Network type is only a trigger; HTTP success determines actual reachability.
class SyncCoordinator extends StatefulWidget {
  final Widget child;
  final DatabaseHelper dbHelper;
  final SettingsLocalDataSource settings;
  final Stream<List<ConnectivityResult>>? connectivityChanges;
  const SyncCoordinator({
    super.key,
    required this.child,
    required this.dbHelper,
    required this.settings,
    this.connectivityChanges,
  });
  @override
  State<SyncCoordinator> createState() => _SyncCoordinatorState();
}

class _SyncCoordinatorState extends State<SyncCoordinator>
    with WidgetsBindingObserver {
  StreamSubscription<List<ConnectivityResult>>? _network;
  StreamSubscription<void>? _changes;
  Timer? _retry;
  Timer? _debounce;
  bool _active = true;
  bool _syncAgain = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _network =
        (widget.connectivityChanges ?? Connectivity().onConnectivityChanged)
            .listen((_) => _schedule(), onError: (_) => _schedule());
    _changes = widget.dbHelper.changes.listen((_) => _schedule());
    _retry = Timer.periodic(const Duration(seconds: 60), (_) => _schedule());
    _schedule();
  }

  void _schedule() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted || !_active || widget.settings.getUserId() == null) return;
      if (context.read<SyncBloc>().state is SyncInProgress) {
        _syncAgain = true;
        return;
      }
      context.read<SyncBloc>().add(TriggerSync());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) _schedule();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _network?.cancel();
    _changes?.cancel();
    _retry?.cancel();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<AuthBloc, AuthState>(
        listener: (_, state) {
          if (state is Authenticated) {
            _schedule();
          } else if (state is Unauthenticated) {
            _debounce?.cancel();
            _syncAgain = false;
            context.read<CustomerBloc>().add(LoadCustomers(reset: true));
            context.read<SiteBloc>().add(const LoadSites(reset: true));
            context.read<FieldNoteBloc>().add(
              const LoadFieldNotes(reset: true),
            );
          }
        },
      ),
      BlocListener<SyncBloc, SyncState>(
        listener: (_, state) {
          if (state is SyncSuccess) {
            context.read<CustomerBloc>().add(LoadCustomers());
            context.read<SiteBloc>().add(const RefreshSites());
            context.read<FieldNoteBloc>().add(const RefreshFieldNotes());
          }
          if (_syncAgain && (state is SyncIdle || state is SyncFailure)) {
            _syncAgain = false;
            _schedule();
          }
        },
      ),
    ],
    child: widget.child,
  );
}
