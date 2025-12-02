/// Validation utilities for task input validation
/// 
/// This module provides standalone validation functions and error messages
/// for validating task data before creation or update operations.
library;

/// Error message constants for validation failures
class ValidationErrors {
  static const String emptyTitle = 'Title cannot be empty or whitespace only';
  static const String invalidPriority = 'Priority must be between 1 and 5';
  static const String pastDueDate = 'Due date cannot be in the past';
}

/// Validates that a title is non-empty and not just whitespace
/// 
/// Returns true if the title is valid (contains at least one non-whitespace character)
/// Returns false if the title is empty or contains only whitespace
bool validateTitle(String title) {
  return title.trim().isNotEmpty;
}

/// Validates that priority is within the valid range (1-5)
/// 
/// Returns true if priority is between 1 and 5 (inclusive)
/// Returns false otherwise
bool validatePriority(int priority) {
  return priority >= 1 && priority <= 5;
}

/// Validates that a due date is not in the past
/// 
/// Returns true if the due date is in the future
/// Returns false if the due date is in the past or current moment
bool validateDueDate(DateTime dueDate) {
  return dueDate.isAfter(DateTime.now());
}
