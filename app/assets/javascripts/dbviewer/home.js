// Use DBViewer namespace for utility functions and error handling
document.addEventListener("DOMContentLoaded", async function () {
  // Validate that required utility scripts have loaded
  if (!window.DBViewer || !DBViewer.Utility || !DBViewer.ErrorHandler) {
    console.error(
      "Required DBViewer scripts not loaded. Please check utility.js and error_handler.js."
    );
    return;
  }

  // Destructure the needed functions for easier access
  const { numberWithDelimiter, numberToHumanSize } = DBViewer.Utility;
  const { displayError, handleApiError } = DBViewer.ErrorHandler;
  // Function to update analytics cards
  function updateTablesCount(data) {
    document.getElementById("tables-loading").classList.add("d-none");
    document.getElementById("tables-count").classList.remove("d-none");
    document.getElementById("tables-count").textContent =
      data.total_tables || 0;
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

  // Using error handler from imported module

  async function fetchTableCount() {
    try {
      const response = await fetch(
        document.getElementById("api_tables_path").value,
        {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        }
      );
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      const data = await response.json();
      updateTablesCount(data);
    } catch (error) {
      await handleApiError("tables count", error, () => {
        const loading = document.getElementById("tables-loading");
        const count = document.getElementById("tables-count");
        loading.classList.add("d-none");
        count.classList.remove("d-none");
        count.innerHTML = '<span class="text-danger">Error</span>';
      });
    }
  }

  async function fetchDatabaseSize() {
    try {
      const response = await fetch(
        document.getElementById("size_api_database_path").value,
        {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        }
      );
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      const data = await response.json();
      updateDatabaseSize(data);
    } catch (error) {
      console.error("Error loading database size:", error);
      const loading = document.getElementById("size-loading");
      const count = document.getElementById("size-count");
      loading.classList.add("d-none");
      count.classList.remove("d-none");
      count.innerHTML = '<span class="text-danger">Error</span>';
    }
  }

  async function fetchRecordsCount() {
    try {
      const response = await fetch(
        document.getElementById("records_api_tables_path").value,
        {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        }
      );
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      const data = await response.json();
      updateRecordsData(data);
    } catch (error) {
      console.error("Error loading records count:", error);
      const loading = document.getElementById("records-loading");
      const count = document.getElementById("records-count");
      loading.classList.add("d-none");
      count.classList.remove("d-none");
      count.innerHTML = '<span class="text-danger">Error</span>';
    }
  }

  async function fetchRecentQueries() {
    try {
      const response = await fetch(
        document.getElementById("recent_api_queries_path").value,
        {
          headers: {
            Accept: "application/json",
            "X-Requested-With": "XMLHttpRequest",
          },
        }
      );
      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }
      const data = await response.json();
      updateRecentQueries(data);
    } catch (error) {
      await handleApiError("recent queries", error, () => {
        displayError(
          "recent-queries-container",
          "Error Loading Queries",
          error.message
        );
      });
    }
  }
  // Load database size data (Loading records first to prevent race condition on dbviewer model constant creation)
  await fetchRecordsCount();

  Promise.all([
    fetchTableCount(),
    fetchDatabaseSize(),
    fetchRecentQueries(),
  ]).catch((error) => {
    console.error("Error loading initial data:", error);
  });
});
