import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../blocs/task_bloc_exports.dart';
import '../models/task.dart';
import '../utils/validators.dart';
import '../utils/debouncer.dart';

/// Screen for creating or editing a task with full form validation
class TaskFormScreen extends StatefulWidget {
  final Task? task; // null for create, non-null for edit

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _debouncer = Debouncer(delay: const Duration(milliseconds: 300));

  int _selectedPriority = 3;
  DateTime? _selectedDueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize form with existing task data if editing
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description ?? '';
      _selectedPriority = widget.task!.priority;
      _selectedDueDate = widget.task!.dueDate;
    }
    
    // Add debounced validation listener
    _titleController.addListener(() {
      _debouncer.call(() {
        _formKey.currentState?.validate();
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _debouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Create Task'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: BlocListener<TaskBloc, TaskState>(
        listener: (context, state) {
          if (state is TasksLoaded) {
            // Task was successfully added/updated, navigate back
            if (_isLoading) {
              Navigator.of(context).pop();
            }
          } else if (state is TaskError) {
            // Show error message
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title field with validation
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    hintText: 'Enter task title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                  ),
                  autofocus: !isEditing,
                  enabled: !_isLoading,
                  validator: (value) {
                    if (value == null || !validateTitle(value)) {
                      return ValidationErrors.emptyTitle;
                    }
                    return null;
                  },
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter task description (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),

                // Priority selector section
                Text(
                  'Priority',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildPrioritySelector(),
                const SizedBox(height: 24),

                // Due date picker section
                Text(
                  'Due Date',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildDueDatePicker(),
                const SizedBox(height: 32),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(isEditing ? 'Save' : 'Create'),
                      ),
                    ),
                  ],
                ),
                
                // Delete button (only show when editing)
                if (isEditing) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _isLoading ? null : _handleDelete,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Task'),
                  ),
                ],
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOut),
        ),
      ),
    );
  }

  /// Build priority selector with visual indicators
  Widget _buildPrioritySelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(5, (index) {
        final priority = index + 1;
        final isSelected = priority == _selectedPriority;
        final color = _getPriorityColor(priority);

        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.flag,
                size: 16,
                color: isSelected ? Colors.white : color,
              ),
              const SizedBox(width: 4),
              Text('Priority $priority'),
            ],
          ),
          selected: isSelected,
          onSelected: _isLoading
              ? null
              : (selected) {
                  setState(() {
                    _selectedPriority = priority;
                  });
                },
          selectedColor: color,
          backgroundColor: color.withValues(alpha: 0.1),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          side: BorderSide(
            color: color,
            width: isSelected ? 2 : 1,
          ),
        );
      }),
    );
  }

  /// Build due date picker with clear button
  Widget _buildDueDatePicker() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : _selectDueDate,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedDueDate == null
                          ? 'No due date set'
                          : DateFormat('EEEE, MMMM d, y')
                              .format(_selectedDueDate!),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: _selectedDueDate != null
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                    ),
                    if (_selectedDueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('h:mm a').format(_selectedDueDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_selectedDueDate != null)
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _isLoading
                      ? null
                      : () {
                          setState(() {
                            _selectedDueDate = null;
                          });
                        },
                  tooltip: 'Clear due date',
                ),
            ],
          ),
        ),
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

  /// Handle due date selection
  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDueDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      helpText: 'Select due date',
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: _selectedDueDate != null
            ? TimeOfDay.fromDateTime(_selectedDueDate!)
            : TimeOfDay.now(),
        helpText: 'Select due time',
      );

      if (time != null && mounted) {
        final newDueDate = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        // Validate that the due date is not in the past
        if (!validateDueDate(newDueDate)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(ValidationErrors.pastDueDate),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        setState(() {
          _selectedDueDate = newDueDate;
        });
      }
    }
  }

  /// Handle save button press
  void _handleSave() {
    // Haptic feedback for important action
    HapticFeedback.mediumImpact();
    
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate priority (should always be valid from selector, but double-check)
    if (!validatePriority(_selectedPriority)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ValidationErrors.invalidPriority),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate due date if set
    if (_selectedDueDate != null && !validateDueDate(_selectedDueDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(ValidationErrors.pastDueDate),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Get form values
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    // Show loading state
    setState(() {
      _isLoading = true;
    });

    // Dispatch appropriate event
    if (widget.task != null) {
      // Update existing task
      context.read<TaskBloc>().add(
            UpdateTask(
              id: widget.task!.id,
              title: title,
              description: description.isEmpty ? null : description,
              priority: _selectedPriority,
              dueDate: _selectedDueDate,
            ),
          );
    } else {
      // Create new task
      context.read<TaskBloc>().add(
            AddTask(
              title: title,
              description: description.isEmpty ? null : description,
              priority: _selectedPriority,
              dueDate: _selectedDueDate,
            ),
          );
    }
  }

  /// Handle delete button press
  void _handleDelete() {
    // Haptic feedback
    HapticFeedback.heavyImpact();
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Close dialog
              Navigator.of(context).pop();
              
              // Delete task
              context.read<TaskBloc>().add(DeleteTask(widget.task!.id));
              
              // Close form screen
              Navigator.of(context).pop();
              
              // Show confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Task "${widget.task!.title}" deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
