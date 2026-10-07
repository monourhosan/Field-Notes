import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'data/local/database_helper.dart';
import 'data/local/settings_local_data_source.dart';
import 'data/remote/api_client.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/customer_repository_impl.dart';
import 'data/repositories/site_repository_impl.dart';
import 'data/repositories/field_note_repository_impl.dart';
import 'data/repositories/sync_repository_impl.dart';
import 'data/repositories/settings_repository_impl.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/customer/customer_bloc.dart';
import 'presentation/bloc/site/site_bloc.dart';
import 'presentation/bloc/note/field_note_bloc.dart';
import 'presentation/bloc/sync/sync_bloc.dart';
import 'presentation/bloc/settings/settings_bloc.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite database
  final dbHelper = DatabaseHelper.instance;

  // Initialize Local Settings Data Source
  final settingsDataSource = await SettingsLocalDataSource.create();

  // Initialize ApiClient
  final apiClient = ApiClient(settingsDataSource);

  // Initialize Repositories
  final authRepository = AuthRepositoryImpl(apiClient, settingsDataSource);
  final customerRepository = CustomerRepositoryImpl(dbHelper, apiClient, settingsDataSource);
  final siteRepository = SiteRepositoryImpl(dbHelper, apiClient);
  final fieldNoteRepository = FieldNoteRepositoryImpl(dbHelper, apiClient);
  final syncRepository = SyncRepositoryImpl(dbHelper, apiClient, settingsDataSource);
  final settingsRepository = SettingsRepositoryImpl(settingsDataSource);

  runApp(
    FieldNotesApp(
      authRepository: authRepository,
      customerRepository: customerRepository,
      siteRepository: siteRepository,
      fieldNoteRepository: fieldNoteRepository,
      syncRepository: syncRepository,
      settingsRepository: settingsRepository,
    ),
  );
}

class FieldNotesApp extends StatelessWidget {
  final AuthRepositoryImpl authRepository;
  final CustomerRepositoryImpl customerRepository;
  final SiteRepositoryImpl siteRepository;
  final FieldNoteRepositoryImpl fieldNoteRepository;
  final SyncRepositoryImpl syncRepository;
  final SettingsRepositoryImpl settingsRepository;

  const FieldNotesApp({
    super.key,
    required this.authRepository,
    required this.customerRepository,
    required this.siteRepository,
    required this.fieldNoteRepository,
    required this.syncRepository,
    required this.settingsRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(authRepository),
        ),
        BlocProvider<CustomerBloc>(
          create: (_) => CustomerBloc(customerRepository),
        ),
        BlocProvider<SiteBloc>(
          create: (_) => SiteBloc(siteRepository),
        ),
        BlocProvider<FieldNoteBloc>(
          create: (_) => FieldNoteBloc(fieldNoteRepository),
        ),
        BlocProvider<SyncBloc>(
          create: (_) => SyncBloc(syncRepository),
        ),
        BlocProvider<SettingsBloc>(
          create: (_) => SettingsBloc(settingsRepository),
        ),
      ],
      child: MaterialApp(
        title: 'Field Notes',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
