import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/sync_repository_impl.dart';

class SyncConflictsScreen extends StatefulWidget {
  const SyncConflictsScreen({super.key});
  @override
  State<SyncConflictsScreen> createState() => _SyncConflictsScreenState();
}

class _SyncConflictsScreenState extends State<SyncConflictsScreen> {
  late Future<List<Map<String, Object?>>> _conflicts;
  bool _busy = false;
  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() =>
      _conflicts = context.read<SyncRepositoryImpl>().getConflicts();
  Future<void> _resolve(Map<String, Object?> item, bool keepLocal) async {
    setState(() => _busy = true);
    try {
      await context.read<SyncRepositoryImpl>().resolveConflict(
        item['id'] as String,
        keepLocal: keepLocal,
        entityType: item['entity_type'] as String,
        expectedRevision:
            (jsonDecode(item['local_data'] as String)
                    as Map<String, dynamic>)['local_revision']
                as int?,
      );
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) {
        setState(_reload);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(String? value) {
    if (value == null) return 'Unavailable';
    final data = jsonDecode(value) as Map<String, dynamic>;
    return const JsonEncoder.withIndent('  ')
        .convert(Map.fromEntries(data.entries.where((e) => e.key != 'photo')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Sync conflicts')),
    body: FutureBuilder<List<Map<String, Object?>>>(
      future: _conflicts,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.isEmpty) {
          return const Center(child: Text('No sync conflicts'));
        }
        return ListView(
          children: snapshot.data!
              .map(
                (item) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['message'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Your device'),
                        SelectableText(
                          _describe(item['local_data'] as String?),
                        ),
                        const Text('Server'),
                        SelectableText(
                          _describe(item['server_data'] as String?),
                        ),
                        Wrap(
                          spacing: 12,
                          children: [
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _resolve(item, true),
                              child: const Text('Keep my edit'),
                            ),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => _resolve(item, false),
                              child: const Text('Use server version'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    ),
  );
}
