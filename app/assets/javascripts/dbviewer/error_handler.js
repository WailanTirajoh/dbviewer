/**
 * DBViewer Error Handler
 * Provides consistent error handling across the application
 */

// Create a global namespace for DBViewer if it doesn't exist yet
window.DBViewer = window.DBViewer || {};

/**
 * Display an error message in a container
 * @param {string} containerId - The ID of the container to show the error in
 * @param {string} title - Error title
 * @param {string} message - Error message
 * @param {string} details - Optional details about the error
 */
function displayError(containerId, title, message, details = "") {
  const container = document.getElementById(containerId);
  if (!container) {
    console.error(`Error container ${containerId} not found`);
    return;
  }

  let detailsHtml = "";
  if (details) {
    detailsHtml = `<small class="text-muted">${details}</small>`;
  }

  container.innerHTML = `
    <div class="text-center my-4 text-danger">
      <i class="bi bi-exclamation-triangle fs-2 d-block mb-2"></i>
      <p class="mb-1">${title}</p>
      <div>${message}</div>
      ${detailsHtml}
    </div>
  `;
}

/**
 * Handle API fetch errors with consistent error handling and logging
 * @param {string} endpoint - The API endpoint being accessed
 * @param {Error} error - The error that occurred
 * @param {Function} errorCallback - Callback function to handle UI updates on error
 */
async function handleApiError(endpoint, error, errorCallback) {
  console.error(`Error fetching from ${endpoint}:`, error);

  if (typeof errorCallback === "function") {
    errorCallback(error);
  }

  // You could add additional error tracking here, like sending to a monitoring service
}

// Expose error handling functions globally
DBViewer.ErrorHandler = {
  displayError,
  handleApiError,
};
