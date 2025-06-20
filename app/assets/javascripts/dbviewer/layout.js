document.addEventListener("DOMContentLoaded", function () {
  // Theme toggle functionality
  const themeToggleBtn = document.querySelector(".theme-toggle");
  const htmlElement = document.documentElement;

  // Check for saved theme preference or respect OS preference
  const prefersDarkMode = window.matchMedia(
    "(prefers-color-scheme: dark)"
  ).matches;
  const savedTheme = localStorage.getItem("dbviewerTheme");

  // Set initial theme
  if (savedTheme) {
    htmlElement.setAttribute("data-bs-theme", savedTheme);
  } else if (prefersDarkMode) {
    htmlElement.setAttribute("data-bs-theme", "dark");
    localStorage.setItem("dbviewerTheme", "dark");
  }

  // Toggle theme when button is clicked
  if (themeToggleBtn) {
    themeToggleBtn.addEventListener("click", function () {
      const currentTheme = htmlElement.getAttribute("data-bs-theme");
      const newTheme = currentTheme === "dark" ? "light" : "dark";

      // Update theme
      htmlElement.setAttribute("data-bs-theme", newTheme);
      localStorage.setItem("dbviewerTheme", newTheme);

      // Dispatch event for other components to respond to theme change (Monaco editor)
      const themeChangeEvent = new CustomEvent("dbviewerThemeChanged", {
        detail: { theme: newTheme },
      });
      document.dispatchEvent(themeChangeEvent);
    });
  }

  // Check if styles are loaded properly
  const styleCheck = getComputedStyle(
    document.documentElement
  ).getPropertyValue("--dbviewer-styles-loaded");
  if (!styleCheck) {
    console.log(
      "DBViewer: Using fallback inline styles (asset pipeline may not be available)"
    );
  } else {
    console.log("DBViewer: External CSS loaded successfully");
  }

  const toggleBtn = document.querySelector(".dbviewer-sidebar-toggle");
  const closeBtn = document.querySelector(".dbviewer-sidebar-close");
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

  if (toggleBtn) {
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
  }

  if (closeBtn) {
    closeBtn.addEventListener("click", function () {
      hideSidebar();
    });
  }

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
  if (offcanvasElement) {
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
  }
});
