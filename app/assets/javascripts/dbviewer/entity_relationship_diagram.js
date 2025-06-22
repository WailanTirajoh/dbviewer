document.addEventListener("DOMContentLoaded", function () {
  // Validate that required utility scripts have loaded
  if (!window.DBViewer || !DBViewer.Utility || !DBViewer.ErrorHandler) {
    console.error(
      "Required DBViewer scripts not loaded. Please check utility.js and error_handler.js."
    );
    return;
  }

  // Destructure the needed functions for easier access
  const { debounce, ThemeManager } = DBViewer.Utility;
  const { displayError } = DBViewer.ErrorHandler;
  // Check if mermaid is loaded first
  if (typeof mermaid === "undefined") {
    console.error("Mermaid library not loaded!");
    displayError(
      "erd-container",
      "Mermaid Library Not Loaded",
      "The diagram library could not be loaded. Please check your internet connection and try again."
    );
    return;
  }

  // Initialize mermaid with theme detection like mini ERD
  mermaid.initialize({
    startOnLoad: true,
    theme: ThemeManager.getCurrentTheme() === "dark" ? "dark" : "default",
    securityLevel: "loose",
    er: {
      diagramPadding: 20,
      layoutDirection: "TB",
      minEntityWidth: 100,
      minEntityHeight: 75,
      entityPadding: 15,
      stroke: "gray",
      fill: "honeydew",
      fontSize: 20,
    },
  });

  // Function to show error messages - using our custom error handler with specific UI adjustments
  function showError(title, message, details = "") {
    const errorContainer = document.getElementById("erd-error");
    const errorMessage = document.getElementById("erd-error-message");
    const errorDetails = document.getElementById("erd-error-details");
    const loadingIndicator = document.getElementById("erd-loading");

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

  // ER Diagram download functionality
  let diagramReady = false;

  // Function to show a temporary downloading indicator
  function showDownloadingIndicator(format) {
    // Create toast element
    const toastEl = document.createElement("div");
    toastEl.className = "position-fixed bottom-0 end-0 p-3";
    toastEl.style.zIndex = "5000";
    toastEl.innerHTML = `
        <div class="toast show" role="alert" aria-live="assertive" aria-atomic="true">
          <div class="toast-header">
            <strong class="me-auto"><i class="bi bi-download"></i> Downloading ERD</strong>
            <small>just now</small>
            <button type="button" class="btn-close" data-bs-dismiss="toast" aria-label="Close"></button>
          </div>
          <div class="toast-body">
            <div class="d-flex align-items-center">
              <div class="spinner-border spinner-border-sm me-2" role="status">
                <span class="visually-hidden">Loading...</span>
              </div>
              Preparing ${format} file for download...
            </div>
          </div>
        </div>
      `;

    document.body.appendChild(toastEl);

    // Automatically remove after a delay
    setTimeout(() => {
      toastEl.remove();
    }, 3000);
  }

  // Generate the ERD diagram
  const tables = JSON.parse(document.getElementById("tables").value);

  // Initialize empty relationships - will be loaded asynchronously
  let relationships = [];
  let relationshipsLoaded = false;

  // Function to fetch relationships asynchronously
  async function fetchRelationships() {
    const apiPath = document.getElementById("relationships_api_path").value;
    updateRelationshipsStatus(false, "Requesting relationships data...");
    try {
      const response = await fetch(apiPath, {
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest",
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      updateRelationshipsStatus(false, "Processing relationships data...");
      const data = await response.json();
      relationships = data.relationships || [];
      relationshipsLoaded = true;
      updateRelationshipsStatus(
        true,
        `Loaded ${relationships.length} relationships`
      );
      return relationships;
    } catch (error) {
      console.error("Error fetching relationships:", error);
      relationshipsLoaded = true; // Mark as loaded even on error to prevent infinite loading
      updateRelationshipsStatus(true, "Failed to load relationships", true);
      return [];
    }
  }

  // Function to update loading status
  function updateLoadingStatus(message) {
    const loadingPhase = document.getElementById("loading-phase");
    if (loadingPhase) {
      loadingPhase.textContent = message;
    }
  }

  // Function to update table loading progress
  function updateTableProgress(loaded, total) {
    const progressBar = document.getElementById("table-progress-bar");
    const progressText = document.getElementById("table-progress-text");

    if (progressBar && progressText) {
      const percentage = total > 0 ? Math.round((loaded / total) * 100) : 0;
      progressBar.style.width = percentage + "%";
      progressBar.setAttribute("aria-valuenow", percentage);
      progressText.textContent = `${loaded} / ${total}`;

      // Update progress bar color based on completion
      if (percentage === 100) {
        progressBar.classList.remove("bg-primary");
        progressBar.classList.add("bg-success");
      }
    }
  }

  // Function to update relationships status
  function updateRelationshipsStatus(loaded, message, isError = false) {
    const relationshipsStatus = document.getElementById("relationships-status");
    if (relationshipsStatus) {
      if (loaded && !isError) {
        relationshipsStatus.innerHTML = `
            <i class="bi bi-check-circle text-success me-2"></i>
            <small class="text-success">${
              message || "Relationships loaded"
            }</small>
          `;
      } else if (loaded && isError) {
        relationshipsStatus.innerHTML = `
            <i class="bi bi-exclamation-triangle text-warning me-2"></i>
            <small class="text-warning">${
              message || "Error loading relationships"
            }</small>
          `;
      } else {
        relationshipsStatus.innerHTML = `
            <div class="spinner-border spinner-border-sm text-secondary me-2" role="status">
              <span class="visually-hidden">Loading...</span>
            </div>
            <small class="text-muted">${
              message || "Loading relationships..."
            }</small>
          `;
      }
    }
  }

  // Create the ER diagram definition in Mermaid syntax
  let mermaidDefinition = "erDiagram\n";

  // We'll store table column data here as we fetch it
  const tableColumns = {};

  // Track loading progress
  let columnsLoadedCount = 0;
  const totalTables = tables.length;

  // Initialize progress bar
  updateTableProgress(0, totalTables);
  updateLoadingStatus("Loading table details...");

  // Start fetching relationships immediately
  updateRelationshipsStatus(false, "Loading relationships...");
  const relationshipsPromise = fetchRelationships();
  const tablePath = document.getElementById("tables_path").value;

  // Function to fetch tables in batches for better performance
  async function fetchTablesInBatches(tables, batchSize = 5) {
    const batches = [];
    for (let i = 0; i < tables.length; i += batchSize) {
      batches.push(tables.slice(i, i + batchSize));
    }

    for (const batch of batches) {
      await Promise.all(batch.map((table) => fetchTableColumns(table.name)));
      // This creates a visual effect of tables loading in batches
    }
  }

  // First pass: add all tables with minimal info and start loading columns
  // Function to fetch column data for a table
  async function fetchTableColumns(tableName) {
    try {
      const response = await fetch(`${tablePath}/${tableName}?format=json`, {
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest",
        },
      });

      if (!response.ok) {
        throw new Error(
          `Failed to fetch table ${tableName}: ${response.status}`
        );
      }

      const data = await response.json();

      if (data && data.columns) {
        tableColumns[tableName] = data.columns;
        columnsLoadedCount++;

        // Update progress bar
        updateTableProgress(columnsLoadedCount, totalTables);

        checkIfReadyToUpdate();
      }
    } catch (error) {
      console.error(`Error fetching columns for table ${tableName}:`, error);
      // Add better error handling
      showError(
        "Table Loading Error",
        `Failed to load columns for table ${tableName}`,
        error.message
      );
      columnsLoadedCount++;
      updateTableProgress(columnsLoadedCount, totalTables);
      checkIfReadyToUpdate();
    }
  }

  // Generate initial table representation
  tables.forEach(function (table) {
    const tableName = table.name;
    mermaidDefinition += `  ${tableName} {\n`;
    mermaidDefinition += `    string id\n`;
    mermaidDefinition += "  }\n";
  });

  // Start loading column data asynchronously in batches
  fetchTablesInBatches(tables);

  // Function to check if we're ready to update the diagram with full data
  function checkIfReadyToUpdate() {
    if (columnsLoadedCount === totalTables && relationshipsLoaded) {
      updateDiagramWithFullData();
    }
  }

  // Wait for relationships to load and check if ready
  relationshipsPromise.finally(() => {
    checkIfReadyToUpdate();
  });

  // Track if we're currently updating the diagram
  let isUpdatingDiagram = false;

  // Function to update the diagram once we have all data
  function updateDiagramWithFullData() {
    // Prevent multiple simultaneous updates
    if (isUpdatingDiagram) return;

    isUpdatingDiagram = true;

    updateLoadingStatus("Generating final diagram...");

    // Regenerate the diagram with complete data
    let updatedDefinition = "erDiagram\n";

    tables.forEach(function (table) {
      const tableName = table.name;
      updatedDefinition += `  ${tableName} {\n`;

      const columns = tableColumns[tableName] || [];
      columns.forEach((column) => {
        updatedDefinition += `    ${column.type || "string"} ${column.name}\n`;
      });

      updatedDefinition += "  }\n";
    });

    // Add relationships
    if (relationships && relationships.length > 0) {
      relationships.forEach(function (rel) {
        updatedDefinition += `  ${rel.from_table} }|--|| ${rel.to_table} : "${rel.from_column} → ${rel.to_column}"\n`;
      });
    } else {
      updatedDefinition +=
        "  %% No relationships found in the database schema\n";
    }

    // Create the diagram element
    const erdDiv = document.createElement("div");
    erdDiv.className = "mermaid";
    erdDiv.innerHTML = updatedDefinition;

    // Create a temporary container for rendering
    const tempContainer = document.createElement("div");
    tempContainer.style.visibility = "hidden";
    tempContainer.style.position = "absolute";
    tempContainer.style.width = "100%";
    tempContainer.appendChild(erdDiv);
    document.body.appendChild(tempContainer);

    // Render the diagram in the temporary container
    mermaid
      .init(undefined, erdDiv)
      .then(function () {
        console.log("Diagram fully rendered with all data");

        try {
          // Remove from temp container without destroying
          tempContainer.removeChild(erdDiv);

          // Hide loading indicator
          document.getElementById("erd-loading").style.display = "none";

          // Clear main container and add the diagram
          container.innerHTML = "";
          container.appendChild(erdDiv);

          // Remove temp container
          document.body.removeChild(tempContainer);

          // Wait a bit for the DOM to stabilize before initializing pan-zoom
          setTimeout(() => {
            setupZoomControls();
            // Mark diagram as ready for download
            diagramReady = true;
            isUpdatingDiagram = false;
          }, 100);
        } catch (err) {
          console.error("Error moving diagram to container:", err);
          isUpdatingDiagram = false;
        }
      })
      .catch(function (error) {
        console.error("Error rendering diagram:", error);
        document.body.removeChild(tempContainer);
        isUpdatingDiagram = false;
        showError(
          "Error rendering diagram",
          "There was an error rendering the entity relationship diagram.",
          error.message
        );
      });
  }

  // Get the container reference for later use
  const container = document.getElementById("erd-container");

  // SVG Pan Zoom instance
  let panZoomInstance = null;

  // Setup zoom controls using svg-pan-zoom library
  function setupZoomControls() {
    const diagramContainer = document.getElementById("erd-container");
    const svgElement = diagramContainer.querySelector("svg");

    if (!svgElement) {
      console.warn("SVG element not found for zoom controls");
      return;
    }

    // Make sure SVG has proper attributes for zooming
    svgElement.setAttribute("width", "100%");
    svgElement.setAttribute("height", "100%");

    // Initialize svg-pan-zoom
    panZoomInstance = svgPanZoom(svgElement, {
      zoomEnabled: true,
      controlIconsEnabled: false,
      fit: true,
      center: true,
      minZoom: 0.1,
      maxZoom: 20,
      zoomScaleSensitivity: 0.3,
      onZoom: function (newZoom) {
        // Update zoom percentage display
        const zoomDisplay = document.getElementById("zoomPercentage");
        if (zoomDisplay) {
          zoomDisplay.textContent = `${Math.round(newZoom * 100)}%`;
        }
      },
    });

    // Set initial zoom to 100%
    panZoomInstance.zoom(1);

    // Add event listeners for zoom controls
    document.getElementById("zoomIn").addEventListener(
      "click",
      debounce(function () {
        panZoomInstance.zoomIn();
      }, 100)
    );

    document.getElementById("zoomOut").addEventListener(
      "click",
      debounce(function () {
        panZoomInstance.zoomOut();
      }, 100)
    );

    document.getElementById("resetView").addEventListener(
      "click",
      debounce(function () {
        panZoomInstance.reset();
      }, 100)
    );

    // Add keyboard shortcuts for zoom controls
    document.addEventListener("keydown", (e) => {
      if (e.ctrlKey || e.metaKey) {
        if (e.key === "+" || e.key === "=") {
          e.preventDefault();
          panZoomInstance.zoomIn();
        } else if (e.key === "-") {
          e.preventDefault();
          panZoomInstance.zoomOut();
        } else if (e.key === "0") {
          e.preventDefault();
          panZoomInstance.reset();
        }
      }
    });

    // Improve ARIA attributes
    document
      .getElementById("zoomIn")
      .setAttribute("aria-label", "Zoom in diagram");
    document
      .getElementById("zoomOut")
      .setAttribute("aria-label", "Zoom out diagram");
    document
      .getElementById("resetView")
      .setAttribute("aria-label", "Reset diagram view");

    // Update initial percentage display
    const zoomDisplay = document.getElementById("zoomPercentage");
    if (zoomDisplay) {
      zoomDisplay.textContent = "100%";
    }

    // Mark diagram as ready for download
    diagramReady = true;
  }

  // Function to download the ERD as SVG
  function downloadAsSVG() {
    if (!diagramReady) {
      alert("Please wait for the diagram to finish loading.");
      return;
    }

    // Show loading indicator
    showDownloadingIndicator("SVG");

    try {
      // Get the SVG element
      const svgElement = document.querySelector("#erd-container svg");
      if (!svgElement) {
        alert("SVG diagram not found.");
        return;
      }

      // Create a clone of the SVG to modify for download
      const clonedSvg = svgElement.cloneNode(true);

      // Set explicit dimensions to ensure proper rendering
      clonedSvg.setAttribute("width", svgElement.getBoundingClientRect().width);
      clonedSvg.setAttribute(
        "height",
        svgElement.getBoundingClientRect().height
      );

      // Convert SVG to a string
      const serializer = new XMLSerializer();
      let svgString = serializer.serializeToString(clonedSvg);

      // Add XML declaration and doctype
      svgString = '<?xml version="1.0" standalone="no"?>\n' + svgString;

      // Create a Blob with the SVG data
      const blob = new Blob([svgString], {
        type: "image/svg+xml;charset=utf-8",
      });

      // Create a timestamp for filename
      const timestamp = new Date().toISOString().replace(/[:.]/g, "-");

      // Create download link and trigger download
      const objectURL = URL.createObjectURL(blob);
      const downloadLink = document.createElement("a");
      downloadLink.href = objectURL;
      downloadLink.download = `database_erd_${timestamp}.svg`;
      document.body.appendChild(downloadLink);
      downloadLink.click();
      document.body.removeChild(downloadLink);

      // Clean up object URL
      setTimeout(() => {
        URL.revokeObjectURL(objectURL);
      }, 100);
    } catch (error) {
      console.error("Error downloading SVG:", error);
      alert("Error downloading SVG. Please check console for details.");
    }
  }

  // Function to download the ERD as PNG
  function downloadAsPNG() {
    if (!diagramReady) {
      alert("Please wait for the diagram to finish loading.");
      return;
    }

    // Show loading indicator
    showDownloadingIndicator("PNG");

    try {
      // Get the SVG element
      const svgElement = document.querySelector("#erd-container svg");
      if (!svgElement) {
        alert("SVG diagram not found.");
        return;
      }

      // Create a clone of the SVG to modify for download
      const clonedSvg = svgElement.cloneNode(true);

      // Set explicit dimensions to ensure proper rendering
      const width = svgElement.getBoundingClientRect().width;
      const height = svgElement.getBoundingClientRect().height;
      clonedSvg.setAttribute("width", width);
      clonedSvg.setAttribute("height", height);

      // Convert SVG to a string
      const serializer = new XMLSerializer();
      const svgString = serializer.serializeToString(clonedSvg);

      // Create a Blob with the SVG data
      const svgBlob = new Blob([svgString], {
        type: "image/svg+xml;charset=utf-8",
      });
      const svgUrl = URL.createObjectURL(svgBlob);

      // Create an Image object to draw to canvas
      const img = new Image();
      img.onload = function () {
        // Create canvas with appropriate dimensions
        const canvas = document.createElement("canvas");
        canvas.width = width * 2; // Scale up for better quality
        canvas.height = height * 2;

        // Get drawing context and scale it
        const ctx = canvas.getContext("2d");
        ctx.scale(2, 2); // Scale up for better quality

        // Draw white background (SVG may have transparency)
        ctx.fillStyle = "white";
        ctx.fillRect(0, 0, width, height);

        // Draw the image onto the canvas
        ctx.drawImage(img, 0, 0, width, height);

        // Create timestamp for filename
        const timestamp = new Date().toISOString().replace(/[:.]/g, "-");

        // Convert canvas to PNG and trigger download
        canvas.toBlob(function (blob) {
          const objectURL = URL.createObjectURL(blob);
          const downloadLink = document.createElement("a");
          downloadLink.href = objectURL;
          downloadLink.download = `database_erd_${timestamp}.png`;
          document.body.appendChild(downloadLink);
          downloadLink.click();
          document.body.removeChild(downloadLink);

          // Clean up object URL
          setTimeout(() => {
            URL.revokeObjectURL(objectURL);
          }, 100);
        }, "image/png");

        // Clean up
        URL.revokeObjectURL(svgUrl);
      };

      // Set the image source to the SVG URL
      img.src = svgUrl;
    } catch (error) {
      console.error("Error downloading PNG:", error);
      alert("Error downloading PNG. Please check console for details.");
    }
  }

  // Set up event listeners for download buttons
  document
    .getElementById("downloadSvg")
    .addEventListener("click", function (e) {
      e.preventDefault();
      downloadAsSVG();
    });

  document
    .getElementById("downloadPng")
    .addEventListener("click", function (e) {
      e.preventDefault();
      downloadAsPNG();
    });

  // Add theme observer to update diagram when theme changes
  function setupThemeObserver() {
    // Listen for our custom theme change event
    document.addEventListener("dbviewerThemeChanged", (event) => {
      const newTheme = event.detail.theme;
      mermaid.initialize({
        theme: newTheme === "dark" ? "dark" : "default",
        // Keep other settings
        securityLevel: "loose",
        er: {
          diagramPadding: 20,
          layoutDirection: "TB",
          minEntityWidth: 100,
          minEntityHeight: 75,
          entityPadding: 15,
          stroke: "gray",
          fill: "honeydew",
          fontSize: 20,
        },
      });

      // Trigger redraw if diagram is already displayed
      if (diagramReady) {
        updateDiagramWithFullData();
      }
    });
  }

  setupThemeObserver();
});
