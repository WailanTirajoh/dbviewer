document.addEventListener("DOMContentLoaded", function () {
  // Validate that required utility scripts have loaded
  if (!window.DBViewer || !DBViewer.Utility) {
    console.error(
      "Required DBViewer utility scripts not loaded. Please check utility.js."
    );
    return;
  }

  // Get debounce from the global namespace
  const { debounce } = DBViewer.Utility;
  const searchInput = document.getElementById("tableSearch");
  const sidebarContent = document.querySelector(".dbviewer-sidebar-content");

  // Storage keys for persistence
  const STORAGE_KEYS = {
    searchFilter: "dbviewer_sidebar_search_filter",
    scrollPosition: "dbviewer_sidebar_scroll_position",
  };

  // Filter function
  const filterTables = debounce(function () {
    const query = searchInput.value.toLowerCase();
    const tableItems = document.querySelectorAll(
      "#tablesList .list-group-item-action"
    );
    let visibleCount = 0;

    // Save the current search filter to localStorage
    localStorage.setItem(STORAGE_KEYS.searchFilter, searchInput.value);

    tableItems.forEach(function (item) {
      // Get the table name from the title attribute for more accurate matching
      const tableName = (item.getAttribute("title") || item.textContent)
        .trim()
        .toLowerCase();

      // Also get the displayed text content for a broader match
      const displayedText = item.textContent.trim().toLowerCase();

      if (tableName.includes(query) || displayedText.includes(query)) {
        item.classList.remove("d-none");
        visibleCount++;
      } else {
        item.classList.add("d-none");
      }
    });

    // Update the tables count in the sidebar
    const tableCountElement = document.getElementById("table-count");
    if (tableCountElement) {
      tableCountElement.textContent = visibleCount;
    }

    // Show/hide no results message
    let noResultsEl = document.getElementById("dbviewer-no-filter-results");
    if (visibleCount === 0 && query !== "") {
      if (!noResultsEl) {
        noResultsEl = document.createElement("div");
        noResultsEl.id = "dbviewer-no-filter-results";
        noResultsEl.className = "list-group-item text-muted text-center py-3";
        noResultsEl.innerHTML =
          '<i class="bi bi-search me-1"></i> No tables match "<span class="fw-bold"></span>"';
        document.getElementById("tablesList").appendChild(noResultsEl);
      }
      noResultsEl.querySelector(".fw-bold").textContent = query;
      noResultsEl.style.display = "block";
    } else if (noResultsEl) {
      noResultsEl.style.display = "none";
    }
  }, 150); // Debounce for 150ms

  // Set up clear button first
  const clearButton = document.createElement("button");
  clearButton.type = "button";
  clearButton.className = "btn btn-sm btn-link position-absolute";
  clearButton.style.right = "15px";
  clearButton.style.top = "50%";
  clearButton.style.transform = "translateY(-50%)";
  clearButton.style.display = "none";
  clearButton.style.color = "#6c757d";
  clearButton.style.fontSize = "0.85rem";
  clearButton.style.padding = "0.25rem";
  clearButton.style.width = "1.5rem";
  clearButton.style.textAlign = "center";
  clearButton.innerHTML = '<i class="bi bi-x-circle"></i>';
  clearButton.addEventListener("click", function () {
    searchInput.value = "";
    // Clear the saved filter from localStorage
    localStorage.removeItem(STORAGE_KEYS.searchFilter);
    // Call filter directly without debouncing for immediate feedback
    filterTables();
    this.style.display = "none";
  });

  const filterContainer = document.querySelector(
    ".dbviewer-table-filter-container"
  );
  if (filterContainer) {
    filterContainer.style.position = "relative";
    filterContainer.appendChild(clearButton);

    searchInput.addEventListener("input", function () {
      clearButton.style.display = this.value ? "block" : "none";
    });
  }

  // Restore saved search filter on page load and apply it immediately
  const savedFilter = localStorage.getItem(STORAGE_KEYS.searchFilter);
  searchInput.value = savedFilter;
  // Show clear button immediately when filter is restored
  clearButton.style.display = "block";
  // Apply filter immediately without debouncing to prevent blinking
  const query = savedFilter.toLowerCase();
  const tableItems = document.querySelectorAll(
    "#tablesList .list-group-item-action"
  );
  let visibleCount = 0;

  tableItems.forEach(function (item) {
    const tableName = (item.getAttribute("title") || item.textContent)
      .trim()
      .toLowerCase();
    const displayedText = item.textContent.trim().toLowerCase();

    if (tableName.includes(query) || displayedText.includes(query)) {
      item.classList.remove("d-none");
      visibleCount++;
    } else {
      item.classList.add("d-none");
    }
  });

  // Update the tables count immediately
  const tableCountElement = document.getElementById("table-count");
  if (tableCountElement) {
    tableCountElement.textContent = visibleCount;
  }

  // Handle no results message immediately
  let noResultsEl = document.getElementById("dbviewer-no-filter-results");
  if (visibleCount === 0 && query !== "") {
    if (!noResultsEl) {
      noResultsEl = document.createElement("div");
      noResultsEl.id = "dbviewer-no-filter-results";
      noResultsEl.className = "list-group-item text-muted text-center py-3";
      noResultsEl.innerHTML =
        '<i class="bi bi-search me-1"></i> No tables match "<span class="fw-bold"></span>"';
      document.getElementById("tablesList").appendChild(noResultsEl);
    }
    noResultsEl.querySelector(".fw-bold").textContent = query;
    noResultsEl.style.display = "block";
  } else if (noResultsEl) {
    noResultsEl.style.display = "none";
  }

  // Restore saved scroll position on page load
  const savedScrollPosition = localStorage.getItem(STORAGE_KEYS.scrollPosition);
  if (savedScrollPosition) {
    // Use requestAnimationFrame to ensure DOM is fully rendered
    requestAnimationFrame(() => {
      sidebarContent.scrollTop = parseInt(savedScrollPosition, 10);
    });
  }

  // Save scroll position on scroll
  const saveScrollPosition = debounce(function () {
    localStorage.setItem(STORAGE_KEYS.scrollPosition, sidebarContent.scrollTop);
  }, 100);

  sidebarContent.addEventListener("scroll", saveScrollPosition);

  // Set up event listeners for the search input
  searchInput.addEventListener("input", filterTables);
  searchInput.addEventListener("keyup", function (e) {
    filterTables();

    // Add keyboard navigation for the filtered list
    if (e.key === "Enter" || e.key === "ArrowDown") {
      e.preventDefault();
      // Focus the first visible table item (not having d-none class)
      const firstVisibleItem = document.querySelector(
        "#tablesList .list-group-item-action:not(.d-none)"
      );
      if (firstVisibleItem) {
        firstVisibleItem.focus();
        // Make sure the item is visible in the scrollable area
        firstVisibleItem.scrollIntoView({
          behavior: "smooth",
          block: "nearest",
        });
      }
    }
  });

  searchInput.addEventListener("search", filterTables); // For clearing via the "x" in some browsers
});
