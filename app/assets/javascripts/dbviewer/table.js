document.addEventListener("DOMContentLoaded", function () {
  const tableName = document.getElementById("table_name").value;

  // Record Detail Modal functionality
  const recordDetailModal = document.getElementById("recordDetailModal");
  if (recordDetailModal) {
    recordDetailModal.addEventListener("show.bs.modal", function (event) {
      // Button that triggered the modal
      const button = event.relatedTarget;

      // Extract record data from button's data attribute
      let recordData;
      let foreignKeys;
      try {
        recordData = JSON.parse(button.getAttribute("data-record-data"));
        foreignKeys = JSON.parse(
          button.getAttribute("data-foreign-keys") || "[]"
        );
      } catch (e) {
        console.error("Error parsing record data:", e);
        recordData = {};
        foreignKeys = [];
      }

      // Update the modal's title with table name
      const modalTitle = recordDetailModal.querySelector(".modal-title");
      modalTitle.textContent = `${tableName} Record Details`;

      // Populate the table with record data
      const tableBody = document.getElementById("recordDetailTableBody");
      tableBody.innerHTML = "";

      // Get all columns
      const columns = Object.keys(recordData);

      // Create rows for each column
      columns.forEach((column) => {
        const row = document.createElement("tr");

        // Create column name cell
        const columnNameCell = document.createElement("td");
        columnNameCell.className = "fw-bold";
        columnNameCell.textContent = column;
        row.appendChild(columnNameCell);

        // Create value cell
        const valueCell = document.createElement("td");
        let cellValue = recordData[column];

        // Format value differently based on type
        if (cellValue === null) {
          valueCell.innerHTML = '<span class="text-muted">NULL</span>';
        } else if (
          typeof cellValue === "string" &&
          cellValue.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
        ) {
          // Handle datetime values
          const date = new Date(cellValue);
          if (!isNaN(date.getTime())) {
            valueCell.textContent = date.toLocaleString();
          } else {
            valueCell.textContent = cellValue;
          }
        } else if (
          typeof cellValue === "string" &&
          (cellValue.startsWith("{") || cellValue.startsWith("["))
        ) {
          // Handle JSON values
          try {
            const jsonValue = JSON.parse(cellValue);
            const formattedJSON = JSON.stringify(jsonValue, null, 2);
            valueCell.innerHTML = `<pre class="mb-0 code-block">${formattedJSON}</pre>`;
          } catch (e) {
            valueCell.textContent = cellValue;
          }
        } else {
          valueCell.textContent = cellValue;
        }

        row.appendChild(valueCell);
        tableBody.appendChild(row);
      });

      // Populate relationships section
      const relationshipsSection = document.getElementById(
        "relationshipsSection"
      );
      const relationshipsContent = document.getElementById(
        "relationshipsContent"
      );
      const reverseForeignKeys = JSON.parse(
        button.dataset.reverseForeignKeys || "[]"
      );

      // Check if we have any relationships to show
      const hasRelationships =
        (foreignKeys && foreignKeys.length > 0) ||
        (reverseForeignKeys && reverseForeignKeys.length > 0);

      if (hasRelationships) {
        relationshipsSection.style.display = "block";
        relationshipsContent.innerHTML = "";

        // Handle belongs_to relationships (foreign keys from this table)
        if (foreignKeys && foreignKeys.length > 0) {
          const activeRelationships = foreignKeys.filter((fk) => {
            const columnValue = recordData[fk.column];
            return (
              columnValue !== null &&
              columnValue !== undefined &&
              columnValue !== ""
            );
          });

          if (activeRelationships.length > 0) {
            relationshipsContent.appendChild(
              createRelationshipSection(
                "Belongs To",
                activeRelationships,
                recordData,
                "belongs_to"
              )
            );
          }
        }

        // Handle has_many relationships (foreign keys from other tables pointing to this table)
        if (reverseForeignKeys && reverseForeignKeys.length > 0) {
          const primaryKeyValue =
            recordData[
              Object.keys(recordData).find((key) => key === "id") ||
                Object.keys(recordData)[0]
            ];

          if (
            primaryKeyValue !== null &&
            primaryKeyValue !== undefined &&
            primaryKeyValue !== ""
          ) {
            const hasManySection = createRelationshipSection(
              "Has Many",
              reverseForeignKeys,
              recordData,
              "has_many",
              primaryKeyValue
            );
            relationshipsContent.appendChild(hasManySection);

            // Fetch relationship counts asynchronously
            fetchRelationshipCounts(
              `${tableName}`,
              primaryKeyValue,
              reverseForeignKeys,
              hasManySection
            );
          }
        }

        // Show message if no active relationships
        if (relationshipsContent.children.length === 0) {
          relationshipsContent.innerHTML = `
              <div class="text-muted small">
                <i class="bi bi-info-circle me-1"></i>
                This record has no active relationships.
              </div>
            `;
        }
      } else {
        relationshipsSection.style.display = "none";
      }
    });
  }

  // Column filter functionality
  const columnFilters = document.querySelectorAll(".column-filter");
  const operatorSelects = document.querySelectorAll(".operator-select");
  const filterForm = document.getElementById("column-filters-form");

  // Add debounce function to reduce form submissions
  function debounce(func, wait) {
    let timeout;
    return function () {
      const context = this;
      const args = arguments;
      clearTimeout(timeout);
      timeout = setTimeout(function () {
        func.apply(context, args);
      }, wait);
    };
  }

  // Function to handle operator changes for IS NULL and IS NOT NULL operators
  function setupNullOperators() {
    operatorSelects.forEach((select) => {
      // Initial setup for existing null operators
      if (select.value === "is_null" || select.value === "is_not_null") {
        const columnName = select.name.match(/\[(.*?)_operator\]/)[1];
        const inputContainer = select.closest(".filter-input-group");
        // Check for display field (the visible disabled field)
        const displayField = inputContainer.querySelector(
          `[data-column="${columnName}_display"]`
        );
        if (displayField) {
          displayField.classList.add("disabled-filter");
        }

        // Make sure the value field properly reflects the null operator
        const valueField = inputContainer.querySelector(
          `[data-column="${columnName}"]`
        );
        if (valueField) {
          valueField.value = select.value;
        }
      }

      // Handle operator changes
      select.addEventListener("change", function () {
        const columnName = this.name.match(/\[(.*?)_operator\]/)[1];
        const filterForm = this.closest("form");
        const inputContainer = this.closest(".filter-input-group");
        const hiddenField = inputContainer.querySelector(
          `[data-column="${columnName}"]`
        );
        const displayField = inputContainer.querySelector(
          `[data-column="${columnName}_display"]`
        );
        const wasNullOperator =
          hiddenField &&
          (hiddenField.value === "is_null" ||
            hiddenField.value === "is_not_null");
        const isNullOperator =
          this.value === "is_null" || this.value === "is_not_null";

        if (isNullOperator) {
          // Configure for null operator
          if (hiddenField) {
            hiddenField.value = this.value;
          }
          // Submit immediately
          filterForm.submit();
        } else if (wasNullOperator) {
          // Clear value when switching from null operator to regular operator
          if (hiddenField) {
            hiddenField.value = "";
          }
        }
      });
    });
  }

  // Function to submit the form
  const submitForm = debounce(function () {
    filterForm.submit();
  }, 500);

  // Initialize the null operators handling
  setupNullOperators();

  // Add event listeners to all filter inputs
  columnFilters.forEach(function (filter) {
    // For text fields use input event
    filter.addEventListener("input", submitForm);

    // For date/time fields also use change event since they have calendar/time pickers
    if (
      filter.type === "date" ||
      filter.type === "datetime-local" ||
      filter.type === "time"
    ) {
      filter.addEventListener("change", submitForm);
    }
  });

  // Add event listeners to operator selects
  operatorSelects.forEach(function (select) {
    select.addEventListener("change", submitForm);
  });

  // Add clear button functionality if there are any filters applied
  const hasActiveFilters = Array.from(columnFilters).some(
    (input) => input.value
  );

  if (hasActiveFilters) {
    // Add a clear filters button
    const paginationContainer =
      document.querySelector('nav[aria-label="Page navigation"]') ||
      document.querySelector(".table-responsive");

    if (paginationContainer) {
      const clearButton = document.createElement("div");
      clearButton.className = "text-center mt-3";
      clearButton.innerHTML =
        '<button type="button" class="btn btn-sm btn-outline-secondary" id="clear-filters">' +
        '<i class="bi bi-x-circle me-1"></i>Clear All Filters</button>';

      paginationContainer.insertAdjacentHTML("afterend", clearButton.outerHTML);

      document
        .getElementById("clear-filters")
        .addEventListener("click", function () {
          // Reset all input values
          columnFilters.forEach((filter) => (filter.value = ""));

          // Reset operator selects to their default values
          operatorSelects.forEach((select) => {
            // Find the first option of the select (usually the default)
            if (select.options.length > 0) {
              select.selectedIndex = 0;
            }
          });

          submitForm();
        });
    }
  }

  // Load Mini ERD when modal is opened
  const miniErdModal = document.getElementById("miniErdModal");
  if (miniErdModal) {
    let isModalLoaded = false;
    let erdData = null;

    miniErdModal.addEventListener("show.bs.modal", function (event) {
      const modalContent = document.getElementById("miniErdModalContent");

      // Set loading state
      modalContent.innerHTML = `
          <div class="modal-header">
            <h5 class="modal-title">Relationships for ${tableName}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body p-0">
            <div id="mini-erd-container" class="w-100 d-flex justify-content-center align-items-center" style="min-height: 450px; height: 100%;">
              <div class="text-center">
                <div class="spinner-border text-primary mb-3" role="status">
                  <span class="visually-hidden">Loading...</span>
                </div>
                <p class="mt-2">Loading relationships diagram...</p>
                <small class="text-muted">This may take a moment for tables with many relationships</small>
              </div>
            </div>
          </div>
        `;

      // Always fetch fresh data when modal is opened
      fetchErdData();
    });

    // Function to fetch ERD data
    function fetchErdData() {
      // Add cache-busting timestamp to prevent browser caching
      const cacheBuster = new Date().getTime();
      const pathElement = document.getElementById("mini_erd_table_path");
      const fetchUrl = `${pathElement.value}?_=${cacheBuster}`;

      fetch(fetchUrl)
        .then((response) => {
          if (!response.ok) {
            throw new Error(
              `Server returned ${response.status} ${response.statusText}`
            );
          }
          return response.json(); // Parse as JSON instead of text
        })
        .then((data) => {
          isModalLoaded = true;
          erdData = data; // Store the data
          renderMiniErd(data);
        })
        .catch((error) => {
          console.error("Error loading mini ERD:", error);
          showErdError(error);
        });
    }

    // Function to show error modal
    function showErdError(error) {
      const modalContent = document.getElementById("miniErdModalContent");
      modalContent.innerHTML = `
          <div class="modal-header">
            <h5 class="modal-title">Relationships for ${tableName}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body p-0">
            <div class="alert alert-danger m-3">
              <i class="bi bi-exclamation-triangle-fill me-2"></i>
              <strong>Error loading relationship diagram</strong>
              <p class="mt-2 mb-0">${error.message}</p>
            </div>
            <div class="m-3">
              <p><strong>Debug Information:</strong></p>
              <p class="mt-3">
                <button class="btn btn-sm btn-primary" onclick="retryLoadingMiniERD()">
                  <i class="bi bi-arrow-clockwise me-1"></i> Retry
                </button>
              </p>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          </div>
        `;
    }

    // Function to render the ERD with Mermaid
    function renderMiniErd(data) {
      const modalContent = document.getElementById("miniErdModalContent");

      // Set up the modal content with container for ERD
      modalContent.innerHTML = `
          <div class="modal-header">
            <h5 class="modal-title">Relationships for ${tableName}</h5>
            <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
          </div>
          <div class="modal-body p-0"> <!-- Removed padding for full width -->
            <div id="mini-erd-container" class="w-100 d-flex justify-content-center align-items-center" style="min-height: 450px; height: 100%;"> <!-- Increased height -->
              <div id="mini-erd-loading" class="d-flex justify-content-center align-items-center" style="height: 100%; min-height: 450px;">
                <div class="text-center">
                  <div class="spinner-border text-primary mb-3" role="status">
                    <span class="visually-hidden">Loading...</span>
                  </div>
                  <p>Generating Relationships Diagram...</p>
                </div>
              </div>
              <div id="mini-erd-error" class="alert alert-danger m-3 d-none">
                <h5>Error generating diagram</h5>
                <p id="mini-erd-error-message">There was an error rendering the relationships diagram.</p>
                <pre id="mini-erd-error-details" class="bg-light p-2 small mt-2"></pre>
              </div>
            </div>
            <div id="debug-data" class="d-none m-3 border-top pt-3">
              <details>
                <summary>Debug Information</summary>
                <div class="alert alert-info small">
                  <pre id="erd-data-debug" style="max-height: 100px; overflow: auto;">${JSON.stringify(
                    data,
                    null,
                    2
                  )}</pre>
                </div>
              </details>
            </div>
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
          </div>
        `;

      try {
        const tables = data.tables || [];
        const relationships = data.relationships || [];

        // Validate data before proceeding
        if (!Array.isArray(tables) || !Array.isArray(relationships)) {
          showDiagramError(
            "Invalid data format",
            "The relationship data is not in the expected format."
          );
          console.error("Invalid data format received:", data);
          return;
        }

        console.log(
          `Found ${tables.length} tables and ${relationships.length} relationships`
        );

        // Create the ER diagram definition in Mermaid syntax
        let mermaidDefinition = "erDiagram\n";

        // Add tables to the diagram - ensure we have at least one table
        if (tables.length === 0) {
          mermaidDefinition += `  ${tableName.gsub(/[^\w]/, "_")} {\n`;
          mermaidDefinition += `    string id PK\n`;
          mermaidDefinition += `  }\n`;
        } else {
          tables.forEach(function (table) {
            const tableName = table.name;

            if (!tableName) {
              console.warn("Table with no name found:", table);
              return; // Skip this table
            }

            // Clean table name for mermaid (remove special characters)
            const cleanTableName = tableName.replace(/[^\w]/g, "_");

            // Make the current table stand out with a different visualization
            if (tableName === `${tableName}`) {
              mermaidDefinition += `  ${cleanTableName} {\n`;
              mermaidDefinition += `    string id PK\n`;
              mermaidDefinition += `  }\n`;
            } else {
              mermaidDefinition += `  ${cleanTableName} {\n`;
              mermaidDefinition += `    string id\n`;
              mermaidDefinition += `  }\n`;
            }
          });
        }

        // Add relationships
        if (relationships && relationships.length > 0) {
          relationships.forEach(function (rel) {
            try {
              // Ensure all required properties exist
              if (!rel.from_table || !rel.to_table) {
                console.error("Missing table in relationship:", rel);
                return; // Skip this relationship
              }

              // Clean up table names for mermaid (remove special characters)
              const fromTable = rel.from_table.replace(/[^\w]/g, "_");
              const toTable = rel.to_table.replace(/[^\w]/g, "_");
              const relationLabel = rel.from_column || "";

              // Customize the display based on direction
              mermaidDefinition += `  ${fromTable} }|--|| ${toTable} : "${relationLabel}"\n`;
            } catch (err) {
              console.error("Error processing relationship:", err, rel);
            }
          });
        } else {
          // Add a note if no relationships are found
          mermaidDefinition += "  %% No relationships found for this table\n";
        }

        // Log the generated mermaid definition for debugging
        console.log("Mermaid Definition:", mermaidDefinition);

        // Hide the loading indicator first since render might take time
        document.getElementById("mini-erd-loading").style.display = "none";

        // Render the diagram with Mermaid
        mermaid
          .render("mini-erd-graph", mermaidDefinition)
          .then(function (result) {
            console.log("Mermaid rendering successful");

            // Get the container
            const container = document.getElementById("mini-erd-container");

            // Insert the rendered SVG
            container.innerHTML = result.svg;

            // Style the SVG element for better fit
            const svgElement = container.querySelector("svg");
            if (svgElement) {
              // Set size attributes for the SVG
              svgElement.setAttribute("width", "100%");
              svgElement.setAttribute("height", "100%");
              svgElement.style.minHeight = "450px";
              svgElement.style.width = "100%";
              svgElement.style.height = "100%";

              // Set viewBox if not present to enable proper scaling
              if (!svgElement.getAttribute("viewBox")) {
                const width = svgElement.getAttribute("width") || "100%";
                const height = svgElement.getAttribute("height") || "100%";
                svgElement.setAttribute(
                  "viewBox",
                  `0 0 ${parseInt(width) || 1000} ${parseInt(height) || 800}`
                );
              }
            }

            // Apply SVG-Pan-Zoom to make the diagram interactive
            try {
              const svgElement = container.querySelector("svg");
              if (svgElement && typeof svgPanZoom !== "undefined") {
                // Make SVG take the full container width and ensure it has valid dimensions
                svgElement.setAttribute("width", "100%");
                svgElement.setAttribute("height", "100%");

                // Wait for SVG to be fully rendered with proper dimensions
                setTimeout(() => {
                  try {
                    // Get dimensions to ensure they're valid before initializing pan-zoom
                    const clientRect = svgElement.getBoundingClientRect();

                    // Only initialize if we have valid dimensions
                    if (clientRect.width > 0 && clientRect.height > 0) {
                      // Initialize SVG Pan-Zoom with more robust error handling
                      const panZoomInstance = svgPanZoom(svgElement, {
                        zoomEnabled: true,
                        controlIconsEnabled: true,
                        fit: false, // Don't automatically fit on init - can cause the matrix error
                        center: false, // Don't automatically center - can cause the matrix error
                        minZoom: 0.5,
                        maxZoom: 2.5,
                        beforeZoom: function () {
                          // Check if the SVG is valid for zooming
                          return (
                            svgElement.getBoundingClientRect().width > 0 &&
                            svgElement.getBoundingClientRect().height > 0
                          );
                        },
                      });

                      // Store the panZoom instance for resize handling
                      container.panZoomInstance = panZoomInstance;

                      // Manually fit and center after a slight delay
                      setTimeout(() => {
                        try {
                          panZoomInstance.resize();
                          panZoomInstance.fit();
                          panZoomInstance.center();
                        } catch (err) {
                          console.warn(
                            "Error during fit/center operation:",
                            err
                          );
                        }
                      }, 300);

                      // Setup resize observer to maintain full size
                      const resizeObserver = new ResizeObserver(() => {
                        if (container.panZoomInstance) {
                          try {
                            // Reset zoom and center when container is resized
                            container.panZoomInstance.resize();
                            // Only fit and center if the element is visible with valid dimensions
                            if (
                              svgElement.getBoundingClientRect().width > 0 &&
                              svgElement.getBoundingClientRect().height > 0
                            ) {
                              container.panZoomInstance.fit();
                              container.panZoomInstance.center();
                            }
                          } catch (err) {
                            console.warn(
                              "Error during resize observer callback:",
                              err
                            );
                          }
                        }
                      });

                      // Observe the container for size changes
                      resizeObserver.observe(container);

                      // Also handle manual resize on modal resize
                      miniErdModal.addEventListener(
                        "resize.bs.modal",
                        function () {
                          if (container.panZoomInstance) {
                            setTimeout(() => {
                              try {
                                container.panZoomInstance.resize();
                                // Only fit and center if the element is visible with valid dimensions
                                if (
                                  svgElement.getBoundingClientRect().width >
                                    0 &&
                                  svgElement.getBoundingClientRect().height > 0
                                ) {
                                  container.panZoomInstance.fit();
                                  container.panZoomInstance.center();
                                }
                              } catch (err) {
                                console.warn(
                                  "Error during modal resize handler:",
                                  err
                                );
                              }
                            }, 300);
                          }
                        }
                      );
                    } else {
                      console.warn(
                        "Cannot initialize SVG-Pan-Zoom: SVG has invalid dimensions",
                        clientRect
                      );
                    }
                  } catch (err) {
                    console.warn("Error initializing SVG-Pan-Zoom:", err);
                  }
                }, 500); // Increased delay to ensure SVG is fully rendered with proper dimensions
              }
            } catch (e) {
              console.warn("Failed to initialize svg-pan-zoom:", e);
              // Not critical, continue without pan-zoom
            }

            // Add highlighting for the current table after a delay to ensure SVG is fully processed
            setTimeout(function () {
              try {
                const cleanTableName = `${tableName}`.replace(/[^\w]/g, "_");
                const currentTableElement = container.querySelector(
                  `[id*="${cleanTableName}"]`
                );
                if (currentTableElement) {
                  const rect = currentTableElement.querySelector("rect");
                  if (rect) {
                    // Highlight the current table
                    rect.setAttribute(
                      "fill",
                      document.documentElement.getAttribute("data-bs-theme") ===
                        "dark"
                        ? "#2c3034"
                        : "#e2f0ff"
                    );
                    rect.setAttribute(
                      "stroke",
                      document.documentElement.getAttribute("data-bs-theme") ===
                        "dark"
                        ? "#6ea8fe"
                        : "#0d6efd"
                    );
                    rect.setAttribute("stroke-width", "2");
                  }
                }
              } catch (e) {
                console.error("Error highlighting current table:", e);
              }
            }, 100);
          })
          .catch(function (error) {
            console.error("Error rendering mini ERD:", error);
            showDiagramError(
              "Error rendering diagram",
              "There was an error rendering the relationships diagram.",
              error.message || "Unknown error"
            );

            // Show debug data when there's an error
            document.getElementById("debug-data").classList.remove("d-none");
          });
      } catch (error) {
        console.error("Exception in renderMiniErd function:", error);
        showDiagramError(
          "Exception generating diagram",
          "There was an exception processing the relationships diagram.",
          error.message || "Unknown error"
        );

        // Show debug data when there's an error
        document.getElementById("debug-data").classList.remove("d-none");
      }
    }

    // Function to show diagram error
    function showDiagramError(title, message, details = "") {
      const errorContainer = document.getElementById("mini-erd-error");
      const errorMessage = document.getElementById("mini-erd-error-message");
      const errorDetails = document.getElementById("mini-erd-error-details");
      const loadingIndicator = document.getElementById("mini-erd-loading");

      if (loadingIndicator) {
        loadingIndicator.style.display = "none";
      }

      if (errorContainer && errorMessage) {
        // Set error message
        errorMessage.textContent = message;

        // Set error details if provided
        if (details && errorDetails) {
          errorDetails.textContent = details;
          errorDetails.classList.remove("d-none");
        } else if (errorDetails) {
          errorDetails.classList.add("d-none");
        }

        // Show the error container
        errorContainer.classList.remove("d-none");
      }
    }

    // Handle modal shown event - adjust size after the modal is fully visible
    miniErdModal.addEventListener("shown.bs.modal", function (event) {
      // After modal is fully shown, resize the diagram to fit
      const container = document.getElementById("mini-erd-container");
      if (container && container.panZoomInstance) {
        setTimeout(() => {
          try {
            // Check if the SVG still has valid dimensions before operating on it
            const svgElement = container.querySelector("svg");
            if (
              svgElement &&
              svgElement.getBoundingClientRect().width > 0 &&
              svgElement.getBoundingClientRect().height > 0
            ) {
              container.panZoomInstance.resize();
              container.panZoomInstance.fit();
              container.panZoomInstance.center();
            } else {
              console.warn(
                "Cannot perform pan-zoom operations: SVG has invalid dimensions"
              );
            }
          } catch (err) {
            console.warn("Error during modal shown handler:", err);
          }
        }, 500); // Increased delay to ensure modal is fully transitioned and SVG is rendered
      }
    });

    // Handle modal close to reset state for future opens
    miniErdModal.addEventListener("hidden.bs.modal", function (event) {
      // Reset flags and cached data to ensure fresh fetch on next open
      isModalLoaded = false;
      erdData = null;
      console.log("Modal closed, diagram data will be refetched on next open");
    });
  }

  // Function to retry loading the Mini ERD
  function retryLoadingMiniERD() {
    console.log("Retrying loading of mini ERD");
    const modalContent = document.getElementById("miniErdModalContent");

    // Set loading state again
    modalContent.innerHTML = `
        <div class="modal-header">
          <h5 class="modal-title">Relationships for ${tableName}</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body p-0">
          <div id="mini-erd-container" class="w-100 d-flex justify-content-center align-items-center" style="min-height: 450px; height: 100%;">
            <div class="text-center">
              <div class="spinner-border text-primary mb-3" role="status">
                <span class="visually-hidden">Loading...</span>
              </div>
              <p>Retrying to load relationships diagram...</p>
            </div>
          </div>
        </div>
      `;

    // Reset state to ensure fresh fetch
    isModalLoaded = false;
    erdData = null;

    // Retry fetching data
    fetchErdData();
  }

  // Column sorting enhancement
  const sortableColumns = document.querySelectorAll(".sortable-column");
  sortableColumns.forEach((column) => {
    const link = column.querySelector(".column-sort-link");

    // Mouse over effects
    column.addEventListener("mouseenter", () => {
      const sortIcon = column.querySelector(".sort-icon");
      if (sortIcon && sortIcon.classList.contains("invisible")) {
        sortIcon.style.visibility = "visible";
        sortIcon.style.opacity = "0.3";
      }
    });

    column.addEventListener("mouseleave", () => {
      const sortIcon = column.querySelector(".sort-icon");
      if (sortIcon && sortIcon.classList.contains("invisible")) {
        sortIcon.style.visibility = "hidden";
        sortIcon.style.opacity = "0";
      }
    });

    // Keyboard accessibility
    if (link) {
      link.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          link.click();
        }
      });
    }
  });

  // Table fullscreen functionality
  const fullscreenToggle = document.getElementById("fullscreen-toggle");
  const fullscreenIcon = document.getElementById("fullscreen-icon");
  const tableSection = document.getElementById("table-section");

  if (fullscreenToggle && tableSection) {
    // Key for storing fullscreen state in localStorage
    const fullscreenStateKey = `dbviewer-table-fullscreen-${tableName}`;

    // Function to apply fullscreen state
    function applyFullscreenState(isFullscreen) {
      if (isFullscreen) {
        // Enter fullscreen
        tableSection.classList.add("table-fullscreen");
        document.body.classList.add("table-fullscreen-active");
        fullscreenIcon.classList.remove("bi-fullscreen");
        fullscreenIcon.classList.add("bi-fullscreen-exit");
        fullscreenToggle.setAttribute("title", "Exit fullscreen");
      } else {
        // Exit fullscreen
        tableSection.classList.remove("table-fullscreen");
        document.body.classList.remove("table-fullscreen-active");
        fullscreenIcon.classList.remove("bi-fullscreen-exit");
        fullscreenIcon.classList.add("bi-fullscreen");
        fullscreenToggle.setAttribute("title", "Toggle fullscreen");
      }
    }

    // Restore fullscreen state from localStorage on page load
    try {
      const savedState = localStorage.getItem(fullscreenStateKey);
      if (savedState === "true") {
        applyFullscreenState(true);
      }
    } catch (e) {
      // Handle localStorage not available (private browsing, etc.)
      console.warn("Could not restore fullscreen state:", e);
    }

    fullscreenToggle.addEventListener("click", function () {
      const isFullscreen = tableSection.classList.contains("table-fullscreen");
      const newState = !isFullscreen;

      // Apply the new state
      applyFullscreenState(newState);

      // Save state to localStorage
      try {
        localStorage.setItem(fullscreenStateKey, newState.toString());
      } catch (e) {
        // Handle localStorage not available (private browsing, etc.)
        console.warn("Could not save fullscreen state:", e);
      }
    });

    // Exit fullscreen with Escape key
    document.addEventListener("keydown", function (e) {
      if (
        e.key === "Escape" &&
        tableSection.classList.contains("table-fullscreen")
      ) {
        fullscreenToggle.click();
      }
    });
  }

  // Function to copy FactoryBot code
  window.copyToJson = function (button) {
    try {
      // Get record data from data attribute
      const recordData = JSON.parse(button.dataset.recordData);

      // Generate formatted JSON string
      const jsonString = JSON.stringify(recordData, null, 2);

      // Copy to clipboard
      navigator.clipboard
        .writeText(jsonString)
        .then(() => {
          // Show a temporary success message on the button
          const originalTitle = button.getAttribute("title");
          button.setAttribute("title", "Copied!");
          button.classList.remove("btn-outline-secondary");
          button.classList.add("btn-success");

          // Show a toast notification
          if (typeof Toastify === "function") {
            Toastify({
              text: `<span class="toast-icon"><i class="bi bi-clipboard-check"></i></span> JSON data copied to clipboard!`,
              className: "toast-factory-bot",
              duration: 3000,
              gravity: "bottom",
              position: "right",
              escapeMarkup: false,
              style: {
                animation:
                  "slideInRight 0.3s ease-out, slideOutRight 0.3s ease-out 2.7s",
              },
              onClick: function () {
                /* Dismiss toast on click */
              },
            }).showToast();
          }

          setTimeout(() => {
            button.setAttribute("title", originalTitle);
            button.classList.remove("btn-success");
            button.classList.add("btn-outline-secondary");
          }, 2000);
        })
        .catch((err) => {
          console.error("Failed to copy text: ", err);

          // Show error toast
          if (typeof Toastify === "function") {
            Toastify({
              text: '<span class="toast-icon"><i class="bi bi-exclamation-triangle"></i></span> Failed to copy to clipboard',
              className: "bg-danger",
              duration: 3000,
              gravity: "bottom",
              position: "right",
              escapeMarkup: false,
              style: {
                background: "linear-gradient(135deg, #dc3545, #c82333)",
                animation: "slideInRight 0.3s ease-out",
              },
            }).showToast();
          } else {
            alert("Failed to copy to clipboard. See console for details.");
          }
        });
    } catch (error) {
      console.error("Error generating JSON:", error);
      alert("Error generating JSON. See console for details.");
    }
  };

  // Helper function to create relationship sections
  // Function to fetch relationship counts from API
  async function fetchRelationshipCounts(
    tableName,
    recordId,
    relationships,
    hasManySection
  ) {
    try {
      const response = await fetch(
        `/dbviewer/api/tables/${tableName}/relationship_counts?record_id=${recordId}`
      );
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();

      // Update each count in the UI
      const countSpans = hasManySection.querySelectorAll(".relationship-count");

      relationships.forEach((relationship, index) => {
        const countSpan = countSpans[index];
        if (countSpan) {
          const relationshipData = data.relationships.find(
            (r) =>
              r.table === relationship.from_table &&
              r.foreign_key === relationship.column
          );

          if (relationshipData) {
            const count = relationshipData.count;
            let badgeClass = "bg-secondary";
            let badgeText = `${count} record${count !== 1 ? "s" : ""}`;

            // Use different colors based on count
            if (count > 0) {
              badgeClass = count > 10 ? "bg-warning" : "bg-success";
            }

            countSpan.innerHTML = `<span class="badge ${badgeClass}">${badgeText}</span>`;
          } else {
            // Fallback if no data found
            countSpan.innerHTML = '<span class="badge bg-danger">Error</span>';
          }
        }
      });
    } catch (error) {
      console.error("Error fetching relationship counts:", error);

      // Show error state in UI
      const countSpans = hasManySection.querySelectorAll(".relationship-count");
      countSpans.forEach((span) => {
        span.innerHTML = '<span class="badge bg-danger">Error</span>';
      });
    }
  }

  function createRelationshipSection(
    title,
    relationships,
    recordData,
    type,
    primaryKeyValue = null
  ) {
    const section = document.createElement("div");
    section.className = "relationship-section mb-4";

    // Create section header
    const header = document.createElement("h6");
    header.className = "mb-3";
    const icon =
      type === "belongs_to" ? "bi-arrow-up-right" : "bi-arrow-down-left";
    header.innerHTML = `<i class="bi ${icon} me-2"></i>${title}`;
    section.appendChild(header);

    const tableContainer = document.createElement("div");
    tableContainer.className = "table-responsive";

    const table = document.createElement("table");
    table.className = "table table-sm table-bordered";

    // Create header based on relationship type
    const thead = document.createElement("thead");
    if (type === "belongs_to") {
      thead.innerHTML = `
          <tr>
            <th width="25%">Column</th>
            <th width="25%">Value</th>
            <th width="25%">References</th>
            <th width="25%">Action</th>
          </tr>
        `;
    } else {
      thead.innerHTML = `
          <tr>
            <th width="30%">Related Table</th>
            <th width="25%">Foreign Key</th>
            <th width="20%">Count</th>
            <th width="25%">Action</th>
          </tr>
        `;
    }
    table.appendChild(thead);

    // Create body
    const tbody = document.createElement("tbody");

    relationships.forEach((fk) => {
      const row = document.createElement("tr");

      if (type === "belongs_to") {
        const columnValue = recordData[fk.column];
        row.innerHTML = `
            <td class="fw-medium">${fk.column}</td>
            <td><code>${columnValue}</code></td>
            <td>
              <span class="text-muted">${fk.to_table}.</span><strong>${
          fk.primary_key
        }</strong>
            </td>
            <td>
              <a href="/dbviewer/tables/${fk.to_table}?column_filters[${
          fk.primary_key
        }]=${encodeURIComponent(columnValue)}" 
                class="btn btn-sm btn-outline-primary" 
                title="View referenced record in ${fk.to_table}">
                <i class="bi bi-arrow-right me-1"></i>View
              </a>
            </td>
          `;
      } else {
        // For has_many relationships
        row.innerHTML = `
            <td class="fw-medium">${fk.from_table}</td>
            <td>
              <span class="text-muted">${fk.from_table}.</span><strong>${
          fk.column
        }</strong>
            </td>
            <td>
              <span class="relationship-count">
                <span class="badge bg-secondary">
                  <span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>
                  Loading...
                </span>
              </span>
            </td>
            <td>
              <a href="/dbviewer/tables/${fk.from_table}?column_filters[${
          fk.column
        }]=${encodeURIComponent(primaryKeyValue)}" 
                class="btn btn-sm btn-outline-success" 
                title="View all ${
                  fk.from_table
                } records that reference this record">
                <i class="bi bi-list me-1"></i>View Related
              </a>
            </td>
          `;
      }

      tbody.appendChild(row);
    });

    table.appendChild(tbody);
    tableContainer.appendChild(table);
    section.appendChild(tableContainer);

    return section;
  }

  // Configure Mermaid for better ERD diagrams
  mermaid.initialize({
    startOnLoad: false,
    theme:
      document.documentElement.getAttribute("data-bs-theme") === "dark"
        ? "dark"
        : "default",
    securityLevel: "loose",
    er: {
      diagramPadding: 20,
      layoutDirection: "TB",
      minEntityWidth: 100,
      minEntityHeight: 75,
      entityPadding: 15,
      stroke: "gray",
      fill:
        document.documentElement.getAttribute("data-bs-theme") === "dark"
          ? "#2D3748"
          : "#f5f5f5",
      fontSize: 14,
      useMaxWidth: true,
      wrappingLength: 30,
    },
  });

  // Initialize Flatpickr date range picker
  const dateRangeInput = document.getElementById("floatingCreationFilterRange");
  const startHidden = document.getElementById("creation_filter_start");
  const endHidden = document.getElementById("creation_filter_end");

  if (dateRangeInput && typeof flatpickr !== "undefined") {
    console.log("Flatpickr library loaded, initializing date range picker");
    // Store the Flatpickr instance in a variable accessible to all handlers
    let fp;

    // Function to initialize Flatpickr
    function initializeFlatpickr(theme) {
      // Determine theme based on current document theme or passed parameter
      const currentTheme =
        theme ||
        (document.documentElement.getAttribute("data-bs-theme") === "dark"
          ? "dark"
          : "light");

      const config = {
        mode: "range",
        enableTime: true,
        dateFormat: "Y-m-d H:i",
        time_24hr: true,
        allowInput: false,
        clickOpens: true,
        theme: currentTheme,
        animate: true,
        position: "auto",
        static: false,
        appendTo: document.body, // Ensure it renders above other elements
        locale: {
          rangeSeparator: " to ",
          weekdays: {
            shorthand: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"],
            longhand: [
              "Sunday",
              "Monday",
              "Tuesday",
              "Wednesday",
              "Thursday",
              "Friday",
              "Saturday",
            ],
          },
          months: {
            shorthand: [
              "Jan",
              "Feb",
              "Mar",
              "Apr",
              "May",
              "Jun",
              "Jul",
              "Aug",
              "Sep",
              "Oct",
              "Nov",
              "Dec",
            ],
            longhand: [
              "January",
              "February",
              "March",
              "April",
              "May",
              "June",
              "July",
              "August",
              "September",
              "October",
              "November",
              "December",
            ],
          },
        },
        onOpen: function (selectedDates, dateStr, instance) {
          // Add a slight delay to apply theme-specific styling after calendar opens
          setTimeout(() => {
            const calendar = instance.calendarContainer;
            if (calendar) {
              // Apply theme-specific class for additional styling control
              calendar.classList.add(`flatpickr-${currentTheme}`);

              // Ensure proper z-index for offcanvas overlay
              calendar.style.zIndex = "1070";

              // Add elegant entrance animation
              calendar.classList.add("open");
            }
          }, 10);
        },
        onClose: function (selectedDates, dateStr, instance) {
          const calendar = instance.calendarContainer;
          if (calendar) {
            calendar.classList.remove("open");
          }
        },
        onChange: function (selectedDates, dateStr, instance) {
          console.log("Date range changed:", selectedDates);

          if (selectedDates.length === 2) {
            // Format dates for hidden inputs (Rails expects ISO format)
            startHidden.value = selectedDates[0].toISOString().slice(0, 16);
            endHidden.value = selectedDates[1].toISOString().slice(0, 16);

            // Update display with elegant formatting
            const formatOptions = {
              year: "numeric",
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            };

            const startFormatted = selectedDates[0].toLocaleDateString(
              "en-US",
              formatOptions
            );
            const endFormatted = selectedDates[1].toLocaleDateString(
              "en-US",
              formatOptions
            );
            dateRangeInput.value = `${startFormatted} to ${endFormatted}`;
          } else if (selectedDates.length === 1) {
            startHidden.value = selectedDates[0].toISOString().slice(0, 16);
            endHidden.value = "";

            const formatOptions = {
              year: "numeric",
              month: "short",
              day: "numeric",
              hour: "2-digit",
              minute: "2-digit",
              hour12: false,
            };

            const startFormatted = selectedDates[0].toLocaleDateString(
              "en-US",
              formatOptions
            );
            dateRangeInput.value = `${startFormatted} (select end date)`;
          } else {
            startHidden.value = "";
            endHidden.value = "";
            dateRangeInput.value = "";
          }
        },
      };

      return flatpickr(dateRangeInput, config);
    }

    // Initialize date range picker
    fp = initializeFlatpickr();

    // Set initial values if they exist
    if (startHidden.value || endHidden.value) {
      const dates = [];
      if (startHidden.value) {
        dates.push(new Date(startHidden.value));
      }
      if (endHidden.value) {
        dates.push(new Date(endHidden.value));
      }
      fp.setDate(dates);
    }

    // Preset button functionality
    const presetButtons = document.querySelectorAll(".preset-btn");
    presetButtons.forEach((button) => {
      button.addEventListener("click", function (event) {
        event.preventDefault(); // Prevent any form submission

        const preset = this.getAttribute("data-preset");
        const now = new Date();
        let startDate, endDate;

        console.log("Preset button clicked:", preset); // Debug log

        switch (preset) {
          case "lastminute":
            startDate = new Date(now);
            startDate.setMinutes(startDate.getMinutes() - 1);
            endDate = new Date(now);
            break;
          case "last5minutes":
            startDate = new Date(now);
            startDate.setMinutes(startDate.getMinutes() - 5);
            endDate = new Date(now);
            break;
          case "today":
            startDate = new Date(
              now.getFullYear(),
              now.getMonth(),
              now.getDate(),
              0,
              0,
              0
            );
            endDate = new Date(
              now.getFullYear(),
              now.getMonth(),
              now.getDate(),
              23,
              59,
              59
            );
            break;
          case "yesterday":
            const yesterday = new Date(now);
            yesterday.setDate(yesterday.getDate() - 1);
            startDate = new Date(
              yesterday.getFullYear(),
              yesterday.getMonth(),
              yesterday.getDate(),
              0,
              0,
              0
            );
            endDate = new Date(
              yesterday.getFullYear(),
              yesterday.getMonth(),
              yesterday.getDate(),
              23,
              59,
              59
            );
            break;
          case "last7days":
            startDate = new Date(now);
            startDate.setDate(startDate.getDate() - 7);
            startDate.setHours(0, 0, 0, 0);
            endDate = new Date(now);
            endDate.setHours(23, 59, 59, 999);
            break;
          case "last30days":
            startDate = new Date(now);
            startDate.setDate(startDate.getDate() - 30);
            startDate.setHours(0, 0, 0, 0);
            endDate = new Date(now);
            endDate.setHours(23, 59, 59, 999);
            break;
          case "thismonth":
            startDate = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0);
            endDate = new Date(
              now.getFullYear(),
              now.getMonth() + 1,
              0,
              23,
              59,
              59
            );
            break;
        }

        if (startDate && endDate && fp) {
          console.log("Setting dates:", startDate, endDate); // Debug log
          fp.setDate([startDate, endDate]);

          // Also update the hidden inputs directly as a fallback
          startHidden.value = startDate.toISOString().slice(0, 16);
          endHidden.value = endDate.toISOString().slice(0, 16);

          // Update the display value
          const formattedStart =
            startDate.toLocaleDateString() +
            " " +
            startDate.toLocaleTimeString();
          const formattedEnd =
            endDate.toLocaleDateString() + " " + endDate.toLocaleTimeString();
          dateRangeInput.value = formattedStart + " to " + formattedEnd;
        } else {
          console.error(
            "Failed to set dates - startDate:",
            startDate,
            "endDate:",
            endDate,
            "fp:",
            fp
          );
        }
      });
    });

    // Listen for theme changes and update Flatpickr theme
    document.addEventListener("dbviewerThemeChanged", function (e) {
      const newTheme = e.detail.theme === "dark" ? "dark" : "light";
      console.log("Theme changed to:", newTheme);

      // Destroy and recreate with new theme
      if (fp) {
        const currentDates = fp.selectedDates;
        fp.destroy();
        fp = initializeFlatpickr(newTheme);

        // Restore previous values if they existed
        if (currentDates && currentDates.length > 0) {
          fp.setDate(currentDates);
        }
      }
    });

    // Also listen for direct data-bs-theme attribute changes using MutationObserver
    const themeObserver = new MutationObserver(function (mutations) {
      mutations.forEach(function (mutation) {
        if (
          mutation.type === "attributes" &&
          mutation.attributeName === "data-bs-theme"
        ) {
          const newTheme =
            document.documentElement.getAttribute("data-bs-theme") === "dark"
              ? "dark"
              : "light";
          console.log("Theme attribute changed to:", newTheme);

          if (fp) {
            const currentDates = fp.selectedDates;
            fp.destroy();
            fp = initializeFlatpickr(newTheme);

            // Restore previous values if they existed
            if (currentDates && currentDates.length > 0) {
              fp.setDate(currentDates);
            }
          }
        }
      });
    });

    // Start observing theme changes
    themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["data-bs-theme"],
    });
  } else {
    console.error("Date range picker initialization failed:", {
      dateRangeInput: !!dateRangeInput,
      flatpickr: typeof flatpickr !== "undefined",
    });
  }

  // Close offcanvas after form submission
  const form = document.getElementById("floatingCreationFilterForm");
  if (form) {
    form.addEventListener("submit", function () {
      const offcanvas = bootstrap.Offcanvas.getInstance(
        document.getElementById("creationFilterOffcanvas")
      );
      if (offcanvas) {
        setTimeout(() => {
          offcanvas.hide();
        }, 100);
      }
    });
  }
});
