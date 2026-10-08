import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/customer/customer_bloc.dart';
import '../bloc/customer/customer_event.dart';
import '../bloc/customer/customer_state.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/site/site_state.dart';
import '../bloc/note/field_note_bloc.dart';
import '../bloc/note/field_note_event.dart';
import '../bloc/note/field_note_state.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../widgets/sync_banner.dart';
import '../widgets/status_badge.dart';
import 'customer_list_screen.dart';
import 'site_list_screen.dart';
import 'field_note_list_screen.dart';
import 'field_note_editor_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    context.read<CustomerBloc>().add(LoadCustomers());
    context.read<SiteBloc>().add(const LoadSites());
    context.read<FieldNoteBloc>().add(const LoadFieldNotes());
    context.read<SyncBloc>().add(CheckPendingSync());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Field Notes Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.sync),
              tooltip: 'Sync Now',
              onPressed: () {
                context.read<SyncBloc>().add(TriggerSync());
                _refreshData();
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Settings',
              onPressed: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    )
                    .then((_) => _refreshData());
              },
            ),
          ],
        ),
        drawer: _buildDrawer(context),
        body: RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SyncBanner(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome header
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final username = (state is Authenticated)
                              ? state.user.username
                              : 'Worker';
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, $username 👋',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ready for site inspection recording (Online & Offline)',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Metric Cards Grid
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Customers',
                              bloc: BlocBuilder<CustomerBloc, CustomerState>(
                                builder: (context, state) {
                                  final count = (state is CustomerLoaded)
                                      ? state.customers.length
                                      : 0;
                                  return Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.primaryColor,
                                    ),
                                  );
                                },
                              ),
                              icon: Icons.business,
                              color: Colors.blue.shade100,
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const CustomerListScreen(),
                                    ),
                                  )
                                  .then((_) => _refreshData()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Sites',
                              bloc: BlocBuilder<SiteBloc, SiteState>(
                                builder: (context, state) {
                                  final count = (state is SiteLoaded)
                                      ? state.sites.length
                                      : 0;
                                  return Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.secondaryColor,
                                    ),
                                  );
                                },
                              ),
                              icon: Icons.location_city,
                              color: Colors.teal.shade100,
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) => const SiteListScreen(),
                                    ),
                                  )
                                  .then((_) => _refreshData()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              title: 'Field Notes',
                              bloc: BlocBuilder<FieldNoteBloc, FieldNoteState>(
                                builder: (context, state) {
                                  final count = (state is FieldNoteLoaded)
                                      ? state.notes.length
                                      : 0;
                                  return Text(
                                    '$count',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.indigo,
                                    ),
                                  );
                                },
                              ),
                              icon: Icons.assignment,
                              color: Colors.indigo.shade100,
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FieldNoteListScreen(),
                                    ),
                                  )
                                  .then((_) => _refreshData()),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMetricCard(
                              title: 'New Note',
                              bloc: const Text(
                                'Create',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.amber,
                                ),
                              ),
                              icon: Icons.add_circle,
                              color: Colors.amber.shade100,
                              onTap: () => Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FieldNoteEditorScreen(),
                                    ),
                                  )
                                  .then((_) => _refreshData()),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Recent Field Notes Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Recent Field Notes',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => const FieldNoteListScreen(),
                                  ),
                                )
                                .then((_) => _refreshData()),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Recent notes list
                      BlocBuilder<FieldNoteBloc, FieldNoteState>(
                        builder: (context, state) {
                          if (state is FieldNoteLoading) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          if (state is FieldNoteLoaded) {
                            if (state.notes.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'No field notes recorded yet. Tap "+ New Note" to begin!',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            final recent = state.notes.take(5).toList();
                            return Column(
                              children: recent.map((note) {
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    title: Text(
                                      note.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${note.siteName ?? "Site"} • ${note.customerName ?? "Customer"}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    trailing: StatusBadge(status: note.status),
                                    onTap: () {
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  FieldNoteEditorScreen(
                                                    existingNote: note,
                                                  ),
                                            ),
                                          )
                                          .then((_) => _refreshData());
                                    },
                                  ),
                                );
                              }).toList(),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required Widget bloc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color,
                  child: Icon(icon, size: 18, color: AppTheme.textPrimary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            bloc,
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppTheme.primaryColor),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.assignment_turned_in,
                  size: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Field Notes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Offline-First Inspection System',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            onTap: () => Navigator.of(context).pop(),
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Customers'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const CustomerListScreen(),
                    ),
                  )
                  .then((_) => _refreshData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_city_outlined),
            title: const Text('Sites'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const SiteListScreen()),
                  )
                  .then((_) => _refreshData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.assignment_outlined),
            title: const Text('Field Notes'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(
                      builder: (_) => const FieldNoteListScreen(),
                    ),
                  )
                  .then((_) => _refreshData());
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Settings'),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context)
                  .push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  )
                  .then((_) => _refreshData());
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.errorColor),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: AppTheme.errorColor),
            ),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AuthBloc>().add(LogoutRequested());
            },
          ),
        ],
      ),
    );
  }
}
