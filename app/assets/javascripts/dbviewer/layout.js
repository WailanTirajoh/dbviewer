document.addEventListener("DOMContentLoaded", function () {
  // Validate that required utility scripts have loaded
  if (!window.DBViewer || !DBViewer.Utility) {
    console.error(
      "Required DBViewer utility scripts not loaded. Please check utility.js."
    );
    return;
  }

  // Get ThemeManager from the global namespace
  const { ThemeManager } = DBViewer.Utility;

  // Theme toggle functionality
  const themeToggleBtn = document.querySelector(".theme-toggle");

  // Initialize theme based on saved preference or OS preference
  ThemeManager.initialize();

  // Toggle theme when button is clicked
  if (themeToggleBtn) {
    themeToggleBtn.addEventListener("click", function () {
      ThemeManager.toggleTheme();
    });
  }

  const toggleBtn = document.querySelector(".dbviewer-sidebar-toggle");
  const sidebar = document.querySelector(".dbviewer-sidebar");
  const overlay = document.createElement("div");

  // Create and configure overlay for mobile
  overlay.className = "dbviewer-sidebar-overlay";
  document.body.appendChild(overlay);

  function showSidebar() {
    sidebar.classList.add("active");
    document.body.classList.add("dbviewer-sidebar-open");
    setTimeout(() => {
      overlay.classList.add("active");
    }, 50);
  }

  function hideSidebar() {
    sidebar.classList.remove("active");
    overlay.classList.remove("active");
    setTimeout(() => {
      document.body.classList.remove("dbviewer-sidebar-open");
    }, 300);
  }

  toggleBtn.addEventListener("click", function () {
    if (sidebar.classList.contains("active")) {
      hideSidebar();
    } else {
      showSidebar();
      // Focus the search input when sidebar becomes visible
      setTimeout(() => {
        const searchInput = document.getElementById("tableSearch");
        if (searchInput) searchInput.focus();
      }, 300); // Small delay to allow for animation
    }
  });

  overlay.addEventListener("click", function () {
    hideSidebar();
  });

  // Close sidebar on window resize (from mobile to desktop)
  let resizeTimer;
  window.addEventListener("resize", function () {
    clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () {
      if (window.innerWidth >= 992 && sidebar.classList.contains("active")) {
        overlay.classList.remove("active");
      }
    }, 250);
  });

  // Offcanvas enhancement for theme synchronization
  const offcanvasElement = document.getElementById("navbarOffcanvas");

  // Get all theme toggles
  const allThemeToggles = document.querySelectorAll(".theme-toggle");

  // Handle theme change from any toggle button
  allThemeToggles.forEach((toggleBtn) => {
    toggleBtn.addEventListener("click", function () {
      const currentTheme =
        document.documentElement.getAttribute("data-bs-theme") || "light";

      // Update all theme toggle buttons to maintain consistency
      allThemeToggles.forEach((btn) => {
        // Update icon in all theme toggle buttons
        if (currentTheme === "dark") {
          btn.querySelector("span").innerHTML =
            '<i class="bi bi-sun-fill"></i>';
          btn.setAttribute("aria-label", "Switch to light mode");
        } else {
          btn.querySelector("span").innerHTML =
            '<i class="bi bi-moon-fill"></i>';
          btn.setAttribute("aria-label", "Switch to dark mode");
        }
      });
    });
  });

  // Function to sync offcanvas colors with current theme
  function syncOffcanvasWithTheme() {
    const currentTheme =
      document.documentElement.getAttribute("data-bs-theme") || "light";
    if (currentTheme === "dark") {
      offcanvasElement
        .querySelector(".offcanvas-header")
        .classList.remove("bg-light-subtle");
      offcanvasElement
        .querySelector(".offcanvas-header")
        .classList.add("bg-dark-subtle");
    } else {
      offcanvasElement
        .querySelector(".offcanvas-header")
        .classList.remove("bg-dark-subtle");
      offcanvasElement
        .querySelector(".offcanvas-header")
        .classList.add("bg-light-subtle");
    }
  }

  // Sync on page load
  document.addEventListener("DOMContentLoaded", syncOffcanvasWithTheme);

  // Listen for theme changes
  document.addEventListener("dbviewerThemeChanged", syncOffcanvasWithTheme);

  // Handle link click in offcanvas (auto-close on mobile)
  const offcanvasLinks = offcanvasElement.querySelectorAll(
    ".nav-link:not(.dropdown-toggle)"
  );
  offcanvasLinks.forEach((link) => {
    link.addEventListener("click", function () {
      if (window.innerWidth < 992) {
        bootstrap.Offcanvas.getInstance(offcanvasElement).hide();
      }
    });
  });

  // Fix offcanvas backdrop on desktop
  window.addEventListener("resize", function () {
    if (window.innerWidth >= 992) {
      const offcanvasInstance =
        bootstrap.Offcanvas.getInstance(offcanvasElement);
      if (offcanvasInstance) {
        offcanvasInstance.hide();
      }
      // Also remove any backdrop
      const backdrop = document.querySelector(".offcanvas-backdrop");
      if (backdrop) {
        backdrop.remove();
      }
    }
  });
});
