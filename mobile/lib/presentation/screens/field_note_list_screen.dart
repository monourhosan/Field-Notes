import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/sync_status.dart';
import '../bloc/note/field_note_bloc.dart';
import '../bloc/note/field_note_event.dart';
import '../bloc/note/field_note_state.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/site/site_state.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_badge.dart';
import 'field_note_editor_screen.dart';

class FieldNoteListScreen extends StatefulWidget {
  const FieldNoteListScreen({super.key});

  @override
  State<FieldNoteListScreen> createState() => _FieldNoteListScreenState();
}

class _FieldNoteListScreenState extends State<FieldNoteListScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String? _selectedSiteId;
  Timer? _searchDebounce;

  final List<String> _statuses = [
    'ALL',
    'DRAFT',
    'IN_PROGRESS',
    'COMPLETED',
    'PENDING',
  ];

  @override
  void initState() {
    super.initState();
    context.read<FieldNoteBloc>().add(const LoadFieldNotes());
    context.read<SiteBloc>().add(const LoadSites());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    context.read<FieldNoteBloc>().add(
      LoadFieldNotes(
        query: _searchController.text.trim(),
        siteId: _selectedSiteId,
        status: _selectedStatus == 'ALL' ? null : _selectedStatus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy - hh:mm a');

    return Scaffold(
      appBar: AppBar(title: const Text('Field Notes')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                  builder: (_) => const FieldNoteEditorScreen(),
                ),
              )
              .then((_) => _triggerSearch());
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search notes, sites, customers, descriptions...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _triggerSearch();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 250),
                      _triggerSearch,
                    );
                  },
                ),
                const SizedBox(height: 10),
                BlocBuilder<SiteBloc, SiteState>(
                  builder: (context, state) {
                    final sites = state is SiteLoaded ? state.sites : [];
                    return DropdownButtonFormField<String>(
                      key: ValueKey(sites.map((site) => site.id).join('|')),
                      initialValue:
                          sites.any((site) => site.id == _selectedSiteId)
                          ? _selectedSiteId
                          : 'ALL',
                      decoration: const InputDecoration(
                        labelText: 'Filter by site',
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'ALL',
                          child: Text('All sites'),
                        ),
                        ...sites.map(
                          (site) => DropdownMenuItem(
                            value: site.id,
                            child: Text(site.siteName),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        setState(
                          () => _selectedSiteId = value == 'ALL' ? null : value,
                        );
                        _triggerSearch();
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),
                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statuses.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final status = _statuses[index];
                      final isSelected = _selectedStatus == status;
                      return ChoiceChip(
                        label: Text(status),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedStatus = status);
                            _triggerSearch();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Notes List
          Expanded(
            child: BlocBuilder<FieldNoteBloc, FieldNoteState>(
              builder: (context, state) {
                if (state is FieldNoteLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is FieldNoteError) {
                  return Center(child: Text('Error: ${state.message}'));
                }
                if (state is FieldNoteLoaded) {
                  if (state.notes.isEmpty) {
                    return EmptyState(
                      icon: Icons.assignment_outlined,
                      title: 'No Field Notes Found',
                      message: 'Record notes, measurements, photos, and location coordinates during site visits.',
                      actionLabel: 'Create Field Note',
                      onAction: () {
                        Navigator.of(context)
                            .push(
                              MaterialPageRoute(
                                builder: (_) => const FieldNoteEditorScreen(),
                              ),
                            )
                            .then((_) => _triggerSearch());
                      },
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: state.notes.length,
                    itemBuilder: (context, index) {
                      final note = state.notes[index];
                      final isPending = note.syncStatus != SyncStatus.synced;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => FieldNoteEditorScreen(
                                      existingNote: note,
                                    ),
                                  ),
                                )
                                .then((_) => _triggerSearch());
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        note.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    StatusBadge(status: note.status),
                                    if (isPending) ...[
                                      const SizedBox(width: 6),
                                      Tooltip(
                                        message: 'Offline changes pending sync',
                                        child: Icon(
                                          Icons.cloud_upload_outlined,
                                          size: 16,
                                          color: Colors.amber.shade800,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Site: ${note.siteName ?? "Site"} - Customer: ${note.customerName ?? "Customer"}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.secondaryColor,
                                  ),
                                ),
                                if (note.description?.isNotEmpty == true) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    note.description!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    if (note.location?.isNotEmpty == true) ...[
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        note.location!,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    if (note.photo?.isNotEmpty == true) ...[
                                      const Icon(
                                        Icons.photo_outlined,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Photo attached',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                    ],
                                    const Spacer(),
                                    Text(
                                      dateFormat.format(
                                        note.dateTime.toLocal(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
