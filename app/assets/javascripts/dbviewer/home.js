document.addEventListener("DOMContentLoaded", function () {
  // Helper function to format numbers with commas
  function numberWithDelimiter(number) {
    return number.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  }

  // Helper function to format file sizes
  function numberToHumanSize(bytes) {
    if (bytes === null || bytes === undefined) return "N/A";
    if (bytes === 0) return "0 Bytes";

    const k = 1024;
    const sizes = ["Bytes", "KB", "MB", "GB", "TB"];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + " " + sizes[i];
  }

  // Function to update analytics cards
  function updateTablesCount(data) {
    document.getElementById("tables-loading").classList.add("d-none");
    document.getElementById("tables-count").classList.remove("d-none");
    document.getElementById("tables-count").textContent =
      data.total_tables || 0;
  }

  function updateRelationshipsCount(data) {
    document.getElementById("relationships-loading").classList.add("d-none");
    document.getElementById("relationships-count").classList.remove("d-none");
    document.getElementById("relationships-count").textContent =
      data.total_relationships || 0;
  }

  function updateDatabaseSize(data) {
    document.getElementById("size-loading").classList.add("d-none");
    document.getElementById("size-count").classList.remove("d-none");
    document.getElementById("size-count").textContent = numberToHumanSize(
      data.schema_size
    );
  }

  function updateRecordsData(recordsData) {
    // Update records count
    document.getElementById("records-loading").classList.add("d-none");
    document.getElementById("records-count").classList.remove("d-none");
    document.getElementById("records-count").textContent = numberWithDelimiter(
      recordsData.total_records || 0
    );

    // Update largest tables
    updateLargestTables(recordsData);
  }

  // Function to update largest tables
  function updateLargestTables(data) {
    const container = document.getElementById("largest-tables-container");

    if (data.largest_tables && data.largest_tables.length > 0) {
      const tableHtml = `
        <div class="table-responsive">
          <table class="table table-sm table-hover">
            <thead>
              <tr>
                <th>Table Name</th>
                <th class="text-end">Records</th>
              </tr>
            </thead>
            <tbody>
              ${data.largest_tables
                .map(
                  (table) => `
                <tr>
                  <td>
                    <a href="${
                      window.location.origin
                    }${window.location.pathname.replace(/\/$/, "")}/tables/${
                    table.name
                  }">
                      ${table.name}
                    </a>
                  </td>
                  <td class="text-end">${numberWithDelimiter(
                    table.record_count
                  )}</td>
                </tr>
              `
                )
                .join("")}
            </tbody>
          </table>
        </div>
      `;
      container.innerHTML = tableHtml;
    } else {
      container.innerHTML = `
        <div class="text-center my-4 empty-data-message">
          <p>No table data available</p>
        </div>
      `;
    }
  }

  // Function to update recent queries
  function updateRecentQueries(data) {
    const container = document.getElementById("recent-queries-container");
    const linkContainer = document.getElementById("queries-view-all-link");

    if (data.enabled) {
      // Show "View All Logs" link if query logging is enabled
      linkContainer.innerHTML = `
        <a href="${window.location.origin}${window.location.pathname.replace(
        /\/$/,
        ""
      )}/logs" class="btn btn-sm btn-primary">View All Logs</a>
      `;
      linkContainer.classList.remove("d-none");

      if (data.queries && data.queries.length > 0) {
        const tableHtml = `
          <div class="table-responsive">
            <table class="table table-sm table-hover mb-0">
              <thead>
                <tr>
                  <th>Query</th>
                  <th class="text-end" style="width: 120px">Duration</th>
                  <th class="text-end" style="width: 180px">Time</th>
                </tr>
              </thead>
              <tbody>
                ${data.queries
                  .map((query) => {
                    const duration = query.duration_ms;
                    const durationClass =
                      duration > 100 ? "query-duration-slow" : "query-duration";
                    const timestamp = new Date(query.timestamp);
                    const timeString = timestamp.toLocaleTimeString();

                    return `
                    <tr>
                      <td class="text-truncate" style="max-width: 500px;">
                        <code class="sql-query-code">${query.sql}</code>
                      </td>
                      <td class="text-end">
                        <span class="${durationClass}">
                          ${duration} ms
                        </span>
                      </td>
                      <td class="text-end query-timestamp">
                        <small>${timeString}</small>
                      </td>
                    </tr>
                  `;
                  })
                  .join("")}
              </tbody>
            </table>
          </div>
        `;
        container.innerHTML = tableHtml;
      } else {
        container.innerHTML = `
          <div class="text-center my-4 empty-data-message">
            <p>No queries recorded yet</p>
          </div>
        `;
      }
    } else {
      container.innerHTML = `
        <div class="text-center my-4 empty-data-message">
          <p>Query logging is disabled</p>
          <small class="text-muted">Enable it in the configuration to see SQL queries here</small>
        </div>
      `;
    }
  }

  // Function to show error state
  function showError(containerId, message) {
    const container = document.getElementById(containerId);
    container.innerHTML = `
      <div class="text-center my-4 text-danger">
        <i class="bi bi-exclamation-triangle fs-2 d-block mb-2"></i>
        <p>Error loading data</p>
        <small>${message}</small>
      </div>
    `;
  }

  // Load tables count data
  fetch(document.getElementById("api_tables_path").value, {
    headers: {
      Accept: "application/json",
      "X-Requested-With": "XMLHttpRequest",
    },
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then((data) => {
      updateTablesCount(data);
    })
    .catch((error) => {
      console.error("Error loading tables count:", error);
      const loading = document.getElementById("tables-loading");
      const count = document.getElementById("tables-count");
      loading.classList.add("d-none");
      count.classList.remove("d-none");
      count.innerHTML = '<span class="text-danger">Error</span>';
    });

  // Load database size data
  fetch(document.getElementById("size_api_database_path").value, {
    headers: {
      Accept: "application/json",
      "X-Requested-With": "XMLHttpRequest",
    },
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then((data) => {
      updateDatabaseSize(data);
    })
    .catch((error) => {
      console.error("Error loading database size:", error);
      const loading = document.getElementById("size-loading");
      const count = document.getElementById("size-count");
      loading.classList.add("d-none");
      count.classList.remove("d-none");
      count.innerHTML = '<span class="text-danger">Error</span>';
    });

  // Load records data separately
  fetch(document.getElementById("records_api_tables_path").value, {
    headers: {
      Accept: "application/json",
      "X-Requested-With": "XMLHttpRequest",
    },
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then((recordsData) => {
      updateRecordsData(recordsData);
    })
    .catch((error) => {
      console.error("Error loading records data:", error);
      // Update records-related UI with error state
      const recordsLoading = document.getElementById("records-loading");
      const recordsCount = document.getElementById("records-count");
      recordsLoading.classList.add("d-none");
      recordsCount.classList.remove("d-none");
      recordsCount.innerHTML = '<span class="text-danger">Error</span>';

      showError("largest-tables-container", error.message);
    });

  // Load recent queries data
  fetch(document.getElementById("recent_api_queries_path").value, {
    headers: {
      Accept: "application/json",
      "X-Requested-With": "XMLHttpRequest",
    },
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      return response.json();
    })
    .then((data) => {
      updateRecentQueries(data);
    })
    .catch((error) => {
      console.error("Error loading recent queries:", error);
      showError("recent-queries-container", error.message);
    });
});
