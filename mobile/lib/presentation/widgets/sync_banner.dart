import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/sync/sync_bloc.dart';
import '../bloc/sync/sync_event.dart';
import '../bloc/sync/sync_state.dart';

class SyncBanner extends StatelessWidget {
  const SyncBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SyncBloc, SyncState>(
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

        if (pendingCount == 0 && !isSyncing && state is! SyncFailure) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSyncing ? Colors.blue.shade50 : Colors.amber.shade50,
            border: Border(
              bottom: BorderSide(
                color: isSyncing ? Colors.blue.shade200 : Colors.amber.shade200,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSyncing ? Icons.sync : Icons.cloud_off,
                size: 20,
                color: isSyncing ? Colors.blue.shade700 : Colors.amber.shade800,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  state is SyncFailure
                      ? state.message
                      : isSyncing
                      ? 'Synchronizing local changes with server...'
                      : '$pendingCount offline change${pendingCount > 1 ? 's' : ''} waiting to sync',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSyncing
                        ? Colors.blue.shade900
                        : Colors.amber.shade900,
                  ),
                ),
              ),
              if (isSyncing)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                TextButton(
                  onPressed: () {
                    context.read<SyncBloc>().add(TriggerSync());
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                  child: const Text(
                    'Sync Now',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
