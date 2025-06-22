/**
 * DBViewer Utility Functions
 * Shared utilities for DBViewer JavaScript modules
 */

// Create a global namespace for DBViewer
window.DBViewer = window.DBViewer || {};

/**
 * Debounces a function call to limit how often it runs
 * @param {Function} func - The function to debounce
 * @param {number} wait - Milliseconds to wait between calls
 * @returns {Function} Debounced function
 */
function debounce(func, wait) {
  let timeout;
  return function (...args) {
    const context = this;
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(context, args), wait);
  };
}

/**
 * Decodes HTML entities in a string
 * @param {string} text - Text with HTML entities
 * @returns {string} Decoded text
 */
function decodeHTMLEntities(text) {
  const textarea = document.createElement("textarea");
  textarea.innerHTML = text;
  return textarea.value;
}

/**
 * Format a number with thousands separators
 * @param {number} number - Number to format
 * @returns {string} Formatted number with commas
 */
function numberWithDelimiter(number) {
  return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

/**
 * Convert bytes to human-readable file size
 * @param {number} bytes - Size in bytes
 * @returns {string} Human readable size (e.g., "4.2 MB")
 */
function numberToHumanSize(bytes) {
  if (bytes === null || bytes === undefined) return "N/A";
  if (bytes === 0) return "0 Bytes";

  const k = 1024;
  const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
  const i = Math.floor(Math.log(bytes) / Math.log(k));

  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
}

/**
 * Helper function to manage theme changes across the application
 */
const ThemeManager = {
  /**
   * Get the current theme
   * @returns {string} 'dark' or 'light'
   */
  getCurrentTheme() {
    return document.documentElement.getAttribute("data-bs-theme") || "light";
  },

  /**
   * Set the theme and save to local storage
   * @param {string} theme - 'dark' or 'light'
   */
  setTheme(theme) {
    if (theme !== "dark" && theme !== "light") {
      console.error("Invalid theme value:", theme);
      return;
    }

    document.documentElement.setAttribute("data-bs-theme", theme);
    localStorage.setItem("dbviewerTheme", theme);

    // Notify all components about theme change
    const themeChangeEvent = new CustomEvent("dbviewerThemeChanged", {
      detail: { theme },
    });
    document.dispatchEvent(themeChangeEvent);
  },

  /**
   * Toggle between dark and light themes
   */
  toggleTheme() {
    const currentTheme = this.getCurrentTheme();
    this.setTheme(currentTheme === "dark" ? "light" : "dark");
  },

  /**
   * Initialize theme based on saved preference or OS preference
   */
  initialize() {
    const prefersDarkMode = window.matchMedia(
      "(prefers-color-scheme: dark)"
    ).matches;
    const savedTheme = localStorage.getItem("dbviewerTheme");

    if (savedTheme) {
      this.setTheme(savedTheme);
    } else if (prefersDarkMode) {
      this.setTheme("dark");
    }
  },
};

// Expose utilities to global namespace
DBViewer.Utility = {
  debounce,
  decodeHTMLEntities,
  numberWithDelimiter,
  numberToHumanSize,
  ThemeManager,
};
