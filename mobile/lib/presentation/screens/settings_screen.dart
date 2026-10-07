import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/auth/auth_event.dart';
import '../bloc/auth/auth_state.dart';
import '../bloc/settings/settings_bloc.dart';
import '../bloc/settings/settings_event.dart';
import '../bloc/settings/settings_state.dart';
import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../bloc/sync/sync_state.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> _statuses = ['DRAFT', 'IN_PROGRESS', 'COMPLETED', 'PENDING'];
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<SettingsBloc>().add(LoadSettings());
    context.read<SyncBloc>().add(CheckPendingSync());
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _showUrlDialog(String currentUrl) {
    _urlController.text = currentUrl;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Backend Server URL'),
        content: TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Server URL',
            hintText: 'http://localhost:8080 or http://10.0.2.2:8080',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newUrl = _urlController.text.trim();
              if (newUrl.isNotEmpty) {
                context.read<SettingsBloc>().add(UpdateBaseUrl(newUrl));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: BlocListener<SyncBloc, SyncState>(
        listener: (context, state) {
          if (state is SyncSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: AppTheme.successColor),
            );
          } else if (state is SyncFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sync error: ${state.message}'), backgroundColor: AppTheme.errorColor),
            );
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Profile Section
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              state.user.username[0].toUpperCase(),
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  state.user.username,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  state.user.email,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 20),

            // Note Preferences Section
            const Text(
              'NOTE PREFERENCES',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),

            Card(
              child: BlocBuilder<SettingsBloc, SettingsState>(
                builder: (context, state) {
                  String defaultStatus = 'DRAFT';
                  if (state is SettingsLoaded) {
                    defaultStatus = state.defaultNoteStatus;
                  }

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Default Note Status',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Automatically applied when creating a new field note. Stored locally on this device.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: defaultStatus,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          ),
                          items: _statuses.map((s) {
                            return DropdownMenuItem(value: s, child: Text(s));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              context.read<SettingsBloc>().add(UpdateDefaultNoteStatus(val));
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Network & Sync Section
            const Text(
              'NETWORK & SYNCHRONIZATION',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 8),

            Card(
              child: Column(
                children: [
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final url = (state is SettingsLoaded) ? state.baseUrl : 'http://localhost:8080';
                      return ListTile(
                        leading: const Icon(Icons.dns_outlined, color: AppTheme.primaryColor),
                        title: const Text('Server Backend URL', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(url, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                        trailing: const Icon(Icons.edit_outlined, size: 20),
                        onTap: () => _showUrlDialog(url),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  BlocBuilder<SyncBloc, SyncState>(
                    builder: (context, state) {
                      int pendingCount = 0;
                      bool isSyncing = false;
                      if (state is SyncInProgress) {
                        isSyncing = true;
                        pendingCount = state.pendingCount;
                      } else if (state is SyncIdle) {
                        pendingCount = state.pendingCount;
                      } else if (state is SyncFailure) {
                        pendingCount = state.pendingCount;
                      }

                      return ListTile(
                        leading: Icon(
                          isSyncing ? Icons.sync : Icons.cloud_sync_outlined,
                          color: isSyncing ? AppTheme.primaryColor : Colors.amber.shade800,
                        ),
                        title: const Text('Offline Sync Status', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          isSyncing
                              ? 'Synchronizing changes with server...'
                              : '$pendingCount change${pendingCount == 1 ? '' : 's'} waiting to push',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        trailing: ElevatedButton(
                          onPressed: isSyncing
                              ? null
                              : () => context.read<SyncBloc>().add(TriggerSync()),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                          child: isSyncing
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Sync'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Sign out
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                if (state is Authenticated) {
                  return OutlinedButton.icon(
                    onPressed: () {
                      context.read<AuthBloc>().add(LogoutRequested());
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: AppTheme.errorColor),
                    label: const Text('Sign Out', style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.errorColor),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }
}
