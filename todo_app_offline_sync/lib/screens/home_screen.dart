import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../blocs/task_bloc_exports.dart';
import '../blocs/auth_bloc_exports.dart';
import '../blocs/connectivity_bloc_exports.dart';
import '../models/task.dart';

/// Home screen displaying the task list with pagination
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _itemsPerPage = 50;
  int _currentPage = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more when scrolled to 90% of the list
      setState(() {
        _currentPage++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Connectivity indicator
          BlocBuilder<ConnectivityBloc, ConnectivityState>(
            builder: (context, connectivityState) {
              if (connectivityState is ConnectivityOffline) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.cloud_off,
                            size: 16,
                            color: Colors.orange[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Offline',
                            style: TextStyle(
                              color: Colors.orange[700],
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Sync button (only visible when authenticated)
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                return IconButton(
                  icon: const Icon(Icons.sync),
                  tooltip: 'Sync Management',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    
                    Navigator.of(context).pushNamed('/sync');
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Auth button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, authState) {
              if (authState is Authenticated) {
                final user = authState.user;
                final displayName = user.displayName ?? user.email ?? 'User';
                
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.account_circle),
                  tooltip: displayName,
                  onSelected: (value) {
                    if (value == 'signout') {
                      context.read<AuthBloc>().add(const SignOut());
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      enabled: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            user.email,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'signout',
                      child: Row(
                        children: [
                          Icon(Icons.logout),
                          SizedBox(width: 8),
                          Text('Sign Out'),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.login),
                  tooltip: 'Sign In',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    
                    // Navigate to auth screen
                    Navigator.of(context).pushNamed('/auth');
                  },
                );
              }
            },
          ),
        ],
      ),
      body: BlocConsumer<TaskBloc, TaskState>(
        listener: (context, state) {
          // Show error messages
          if (state is TaskError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is TasksLoading) {
            return _buildShimmerLoading(context);
          }

          if (state is TasksLoaded) {
            if (state.tasks.isEmpty) {
              return _buildEmptyState(context);
            }
            return _buildTaskList(context, state.tasks);
          }

          if (state is TaskError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading tasks',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<TaskBloc>().add(const LoadTasks());
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Initial state
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Haptic feedback for navigation
          HapticFeedback.lightImpact();
          
          Navigator.of(context).pushNamed('/task/create');
        },
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build shimmer loading animation for initial load
  Widget _buildShimmerLoading(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .shimmer(
              duration: 1500.ms,
              color: Colors.white.withValues(alpha: 0.5),
            );
      },
    );
  }

  /// Build empty state with creative animation
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 120,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          )
              .animate(
                onPlay: (controller) => controller.repeat(reverse: true),
              )
              .scale(
                duration: 2000.ms,
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                curve: Curves.easeInOut,
              )
              .then()
              .scale(
                duration: 2000.ms,
                begin: const Offset(1.1, 1.1),
                end: const Offset(0.9, 0.9),
                curve: Curves.easeInOut,
              ),
          const SizedBox(height: 24),
          Text(
            'No tasks yet!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 200.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first task',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          )
              .animate()
              .fadeIn(duration: 600.ms, delay: 400.ms)
              .slideY(begin: 0.3, end: 0, duration: 600.ms, delay: 400.ms),
        ],
      ),
    );
  }

  /// Build task list with ListView.builder, pagination, and smooth animations
  Widget _buildTaskList(BuildContext context, List<Task> tasks) {
    // Calculate paginated items
    final int totalItems = tasks.length;
    final int displayedItems = (_currentPage + 1) * _itemsPerPage;
    final int itemCount = displayedItems > totalItems ? totalItems : displayedItems;
    
    return ListView.builder(
      controller: _scrollController,
      itemCount: itemCount + (itemCount < totalItems ? 1 : 0), // +1 for loading indicator
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        // Show loading indicator at the end
        if (index == itemCount) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        final task = tasks[index];
        return _buildTaskCard(context, task, index);
      },
    );
  }

  /// Build individual task card with swipe gestures and animations
  Widget _buildTaskCard(BuildContext context, Task task, int index) {
    final dismissible = Dismissible(
      key: Key(task.id),
      background: _buildSwipeBackground(
        context,
        Colors.green,
        Icons.check,
        'Complete',
        Alignment.centerLeft,
      ),
      secondaryBackground: _buildSwipeBackground(
        context,
        Colors.red,
        Icons.delete,
        'Delete',
        Alignment.centerRight,
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe right - complete
          context.read<TaskBloc>().add(ToggleTaskCompletion(task.id));
          
          // Show celebration animation for completion
          if (!task.completed) {
            _showCompletionCelebration(context);
          }
          
          return false; // Don't dismiss, just toggle
        } else {
          // Swipe left - delete
          return await _showDeleteConfirmation(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          // Haptic feedback for deletion
          HapticFeedback.heavyImpact();
          
          // Delete confirmed
          context.read<TaskBloc>().add(DeleteTask(task.id));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Task "${task.title}" deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  // Note: Undo would require storing deleted task temporarily
                  // For now, just show the message
                },
              ),
            ),
          );
        }
      },
      child: Hero(
        tag: 'task_${task.id}',
        child: Material(
          type: MaterialType.transparency,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: InkWell(
              onTap: () {
                // Haptic feedback for navigation
                HapticFeedback.lightImpact();
                
                Navigator.of(context).pushNamed(
                  '/task/edit',
                  arguments: task,
                );
              },
              child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion checkbox
                Checkbox(
                  value: task.completed,
                  onChanged: (value) {
                    // Haptic feedback for important action
                    HapticFeedback.mediumImpact();
                    
                    context.read<TaskBloc>().add(ToggleTaskCompletion(task.id));
                    
                    // Show celebration animation for completion
                    if (value == true) {
                      _showCompletionCelebration(context);
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        task.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              decoration: task.completed
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.completed ? Colors.grey : null,
                            ),
                      ),
                      // Description preview
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                    decoration: task.completed
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                        ),
                      ],
                      // Due date badge
                      if (task.dueDate != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14,
                              color: _getDueDateColor(task.dueDate!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(task.dueDate!),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _getDueDateColor(task.dueDate!),
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                // Priority indicator
                _buildPriorityIndicator(context, task.priority),
              ],
            ),
          ),
        ),
      ),
    ),
    ),
    );
    
    return dismissible
        .animate()
        .fadeIn(duration: 400.ms, delay: Duration(milliseconds: index * 50))
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          delay: Duration(milliseconds: index * 50),
          curve: Curves.easeOutBack,
        );
  }

  /// Show confetti/celebration animation for task completion
  void _showCompletionCelebration(BuildContext context) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: IgnorePointer(
          child: Center(
            child: Icon(
              Icons.celebration,
              size: 100,
              color: Colors.amber,
            )
                .animate()
                .scale(
                  duration: 600.ms,
                  begin: const Offset(0, 0),
                  end: const Offset(1.5, 1.5),
                  curve: Curves.elasticOut,
                )
                .fadeOut(duration: 600.ms, delay: 200.ms)
                .then()
                .callback(callback: (_) {
                  // Remove overlay after animation
                }),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Remove overlay after animation completes
    Future.delayed(const Duration(milliseconds: 800), () {
      overlayEntry.remove();
    });
  }

  /// Build swipe background for dismissible
  Widget _buildSwipeBackground(
    BuildContext context,
    Color color,
    IconData icon,
    String label,
    Alignment alignment,
  ) {
    return Container(
      color: color,
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build priority indicator with color coding
  Widget _buildPriorityIndicator(BuildContext context, int priority) {
    final color = _getPriorityColor(priority);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            'P$priority',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for priority level
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red; // Urgent
      case 4:
        return Colors.orange; // High
      case 3:
        return Colors.yellow[700]!; // Medium
      case 2:
        return Colors.blue; // Low
      case 1:
        return Colors.grey; // Minimal
      default:
        return Colors.grey;
    }
  }

  /// Get color for due date based on urgency
  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return Colors.red; // Overdue
    } else if (difference.inHours < 24) {
      return Colors.orange; // Due soon
    } else if (difference.inDays < 7) {
      return Colors.blue; // Due this week
    } else {
      return Colors.grey; // Due later
    }
  }

  /// Format due date for display
  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    } else if (difference.inHours < 1) {
      return 'Due in ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Due in ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'Due in ${difference.inDays}d';
    } else {
      return DateFormat('MMM d, y').format(dueDate);
    }
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
