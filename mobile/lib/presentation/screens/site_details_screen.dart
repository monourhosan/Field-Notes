import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/entities/site.dart';
import '../bloc/site/site_bloc.dart';
import '../bloc/site/site_event.dart';
import '../bloc/note/field_note_bloc.dart';
import '../bloc/note/field_note_event.dart';
import '../bloc/note/field_note_state.dart';
import '../widgets/status_badge.dart';
import 'field_note_editor_screen.dart';

class SiteDetailsScreen extends StatefulWidget {
  final Site site;

  const SiteDetailsScreen({super.key, required this.site});

  @override
  State<SiteDetailsScreen> createState() => _SiteDetailsScreenState();
}

class _SiteDetailsScreenState extends State<SiteDetailsScreen> {
  late Site _site;

  @override
  void initState() {
    super.initState();
    _site = widget.site;
    context.read<FieldNoteBloc>().add(LoadFieldNotes(siteId: _site.id));
  }

  void _editSite() {
    final nameController = TextEditingController(text: _site.siteName);
    final addressController = TextEditingController(text: _site.address ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Site'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Site Name *'),
                  validator: (val) => (val == null || val.trim().isEmpty)
                      ? 'Please enter site name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  final newName = nameController.text.trim();
                  final newAddress = addressController.text.trim();
                  context.read<SiteBloc>().add(
                    UpdateSiteEvent(
                      id: _site.id,
                      customerId: _site.customerId,
                      siteName: newName,
                      address: newAddress,
                    ),
                  );
                  setState(() {
                    _site = _site.copyWith(
                      siteName: newName,
                      address: newAddress,
                    );
                  });
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Site'),
        content: Text(
          'Are you sure you want to delete "${_site.siteName}" and all its field notes?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              context.read<SiteBloc>().add(
                DeleteSiteEvent(_site.id, customerId: _site.customerId),
              );
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_site.siteName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: _editSite,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Details Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _site.siteName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customer: ${_site.customerName ?? "Customer"}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _site.address?.isNotEmpty == true
                                ? _site.address!
                                : 'No address specified',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Field Notes Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notes for this Site',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            FieldNoteEditorScreen(preselectedSiteId: _site.id),
                      ),
                    );
                    if (context.mounted) {
                      context.read<FieldNoteBloc>().add(
                        LoadFieldNotes(siteId: _site.id),
                      );
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Note'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Notes list
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
                  final visible = state.notes
                      .where((note) => note.siteId == _site.id)
                      .toList();
                  if (visible.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Center(
                        child: Text(
                          'No field notes recorded for this site yet.',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: visible.map((note) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            note.title,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            note.description?.isNotEmpty == true
                                ? note.description!
                                : 'No description',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: StatusBadge(status: note.status),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    FieldNoteEditorScreen(existingNote: note),
                              ),
                            );
                            if (context.mounted) {
                              context.read<FieldNoteBloc>().add(
                                LoadFieldNotes(siteId: _site.id),
                              );
                            }
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
    );
  }
}
