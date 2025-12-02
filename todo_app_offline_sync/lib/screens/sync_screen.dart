import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../blocs/auth_bloc_exports.dart';
import '../blocs/sync_bloc_exports.dart';
import '../services/sync_queue_service.dart';
import '../models/sync_queue_item.dart';

/// Screen for managing sync operations and viewing sync status
class SyncScreen extends StatefulWidget {
  const SyncScreen({super.key});

  @override
  State<SyncScreen> createState() => _SyncScreenState();
}

class _SyncScreenState extends State<SyncScreen> {
  List<SyncQueueItem> _queuedOperations = [];
  bool _loadingQueue = false;

  @override
  void initState() {
    super.initState();
    _loadQueuedOperations();
  }

  /// Load queued operations from the sync queue service
  Future<void> _loadQueuedOperations() async {
    setState(() {
      _loadingQueue = true;
    });

    try {
      final syncQueueService = context.read<SyncQueueService>();
      final operations = await syncQueueService.getAllQueuedOperations();
      setState(() {
        _queuedOperations = operations;
        _loadingQueue = false;
      });
    } catch (e) {
      setState(() {
        _loadingQueue = false;
      });
    }
  }

  /// Format timestamp for display
  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(timestamp);
    }
  }

  /// Get operation icon based on type
  IconData _getOperationIcon(SyncOperation operation) {
    switch (operation) {
      case SyncOperation.create:
        return Icons.add_circle_outline;
      case SyncOperation.update:
        return Icons.edit_outlined;
      case SyncOperation.delete:
        return Icons.delete_outline;
    }
  }

  /// Get operation color based on type
  Color _getOperationColor(SyncOperation operation) {
    switch (operation) {
      case SyncOperation.create:
        return Colors.green;
      case SyncOperation.update:
        return Colors.blue;
      case SyncOperation.delete:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sync Management'),
        elevation: 0,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, authState) {
          if (authState is Unauthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please sign in to sync your tasks'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, authState) {
          if (authState is! Authenticated) {
            return _buildUnauthenticatedView();
          }

          return BlocConsumer<SyncBloc, SyncState>(
            listener: (context, syncState) {
              if (syncState is SyncComplete) {
                _loadQueuedOperations();
              }
            },
            builder: (context, syncState) {
              return RefreshIndicator(
                onRefresh: _loadQueuedOperations,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildSyncStatusCard(syncState),
                        const SizedBox(height: 16),
                        _buildSyncActionsCard(syncState),
                        const SizedBox(height: 16),
                        _buildQueuedOperationsCard(),
                        if (syncState is SyncConflict) ...[
                          const SizedBox(height: 16),
                          _buildConflictResolutionCard(syncState),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  /// Build view for unauthenticated users
  Widget _buildUnauthenticatedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Sign In Required',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in with your Google account to sync your tasks across devices.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go Back'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build sync status card
  Widget _buildSyncStatusCard(SyncState syncState) {
    DateTime? lastSyncTime;
    String statusText = 'Ready to sync';
    IconData statusIcon = Icons.cloud_done;
    Color statusColor = Colors.green;

    if (syncState is SyncIdle) {
      lastSyncTime = syncState.lastSyncTime;
      statusText = 'Synced';
      statusIcon = Icons.cloud_done;
      statusColor = Colors.green;
    } else if (syncState is SyncInProgress) {
      statusText = syncState.message;
      statusIcon = Icons.cloud_sync;
      statusColor = Colors.blue;
    } else if (syncState is SyncComplete) {
      lastSyncTime = syncState.syncTime;
      statusText = 'Sync complete';
      statusIcon = Icons.check_circle;
      statusColor = Colors.green;
    } else if (syncState is SyncError) {
      statusText = 'Sync failed';
      statusIcon = Icons.error;
      statusColor = Colors.red;
    } else if (syncState is SyncConflict) {
      statusText = 'Conflicts detected';
      statusIcon = Icons.warning;
      statusColor = Colors.orange;
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sync Status',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: statusColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (syncState is SyncInProgress) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: syncState.progress,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
              const SizedBox(height: 8),
              Text(
                '${(syncState.progress * 100).toInt()}% complete',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (lastSyncTime != null) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Last synced: ${_formatTimestamp(lastSyncTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
            if (syncState is SyncComplete) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.task_alt, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    '${syncState.tasksSynced} tasks synced',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ],
            if (syncState is SyncError) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                syncState.message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.red,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build sync actions card
  Widget _buildSyncActionsCard(SyncState syncState) {
    final isSyncing = syncState is SyncInProgress;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sync Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () {
                            context.read<SyncBloc>().add(const SyncToCloud());
                          },
                    icon: const Icon(Icons.cloud_upload),
                    label: const Text('Upload to Cloud'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isSyncing
                        ? null
                        : () {
                            context.read<SyncBloc>().add(const SyncFromCloud());
                          },
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('Download from Cloud'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build queued operations card
  Widget _buildQueuedOperationsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pending Operations',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (_loadingQueue)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadQueuedOperations,
                    tooltip: 'Refresh',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_queuedOperations.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No pending operations',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _queuedOperations.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final operation = _queuedOperations[index];
                  return ListTile(
                    leading: Icon(
                      _getOperationIcon(operation.operation),
                      color: _getOperationColor(operation.operation),
                    ),
                    title: Text(
                      operation.operation.name.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Task ID: ${operation.taskId.substring(0, 8)}...',
                    ),
                    trailing: Text(
                      _formatTimestamp(operation.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Build conflict resolution card
  Widget _buildConflictResolutionCard(SyncConflict conflictState) {
    return Card(
      elevation: 2,
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Sync Conflicts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              conflictState.message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.orange[900],
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              '${conflictState.conflictingTasks.length} conflicting tasks detected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.orange[800],
                  ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // In the current implementation, conflicts are auto-resolved
                // This button is a placeholder for future manual resolution UI
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Conflicts are automatically resolved using the latest version',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Auto-Resolve Conflicts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}