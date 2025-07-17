// Custom JavaScript for Habit Tracker

document.addEventListener('DOMContentLoaded', function () {
  // Initialize tooltips
  var tooltipTriggerList = [].slice.call(
    document.querySelectorAll('[data-bs-toggle="tooltip"]'),
  );
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });

  // Confirm delete actions
  const deleteButtons = document.querySelectorAll('.btn-delete');
  deleteButtons.forEach((button) => {
    button.addEventListener('click', function (e) {
      if (
        !confirm(
          'Are you sure you want to delete this habit? This action cannot be undone.',
        )
      ) {
        e.preventDefault();
      }
    });
  });

  // Confirm uncomplete actions
  const uncompleteButtons = document.querySelectorAll('.btn-uncomplete');
  uncompleteButtons.forEach((button) => {
    button.addEventListener('click', function (e) {
      if (!confirm('Are you sure you want to remove this completion?')) {
        e.preventDefault();
      }
    });
  });

  // Auto-hide flash messages after 5 seconds
  const flashMessages = document.querySelectorAll('.alert');
  flashMessages.forEach((message) => {
    setTimeout(() => {
      message.style.opacity = '0';
      setTimeout(() => {
        message.remove();
      }, 300);
    }, 5000);
  });
});
