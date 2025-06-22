document.addEventListener("DOMContentLoaded", function () {
  // Validate that required utility scripts have loaded
  if (!window.DBViewer || !DBViewer.Utility || !DBViewer.ErrorHandler) {
    console.error(
      "Required DBViewer scripts not loaded. Please check utility.js and error_handler.js."
    );
    return;
  }

  // Destructure the needed functions for easier access
  const { decodeHTMLEntities, ThemeManager } = DBViewer.Utility;
  const { displayError } = DBViewer.ErrorHandler;

  // Get initial query value from a data attribute to avoid string escaping issues
  const initialQueryEncoded = document
    .getElementById("monaco-editor")
    ?.getAttribute("data-initial-query");
  const initialQuery = initialQueryEncoded
    ? decodeHTMLEntities(initialQueryEncoded)
    : "";

  // Use RequireJS to load Monaco
  require(["vs/editor/editor.main"], function () {
    const initialTheme =
      ThemeManager.getCurrentTheme() === "dark" ? "vs-dark" : "vs";

    const editorContainer = document.getElementById("monaco-editor");
    if (!editorContainer) {
      throw new Error("Monaco editor container not found");
    }

    const editor = monaco.editor.create(editorContainer, {
      value: initialQuery || "",
      language: "sql",
      theme: initialTheme,
      automaticLayout: true, // Resize automatically
      minimap: { enabled: true },
      scrollBeyondLastLine: false,
      lineNumbers: "on",
      renderLineHighlight: "all",
      tabSize: 2,
      wordWrap: "on",
      formatOnPaste: true,
      formatOnType: true,
      autoIndent: "full",
      folding: true,
      glyphMargin: false,
      suggestOnTriggerCharacters: true,
      fixedOverflowWidgets: true,
      quickSuggestions: {
        other: true,
        comments: true,
        strings: true,
      },
      suggest: {
        showKeywords: true,
        showSnippets: true,
        preview: true,
        showIcons: true,
        maxVisibleSuggestions: 12,
      },
    });

    // Theme change listener
    document.addEventListener("dbviewerThemeChanged", (event) => {
      const newTheme = event.detail.theme === "dark" ? "vs-dark" : "vs";
      monaco.editor.setTheme(newTheme);

      // Update editor container border color
      const editorContainer = document.querySelector(
        ".monaco-editor-container"
      );
      editorContainer.style.borderColor =
        event.detail.theme === "dark" ? "#495057" : "#ced4da";

      // Update status bar styling based on theme
      updateStatusBarTheme(event.detail.theme);

      // Update example query buttons
      const exampleQueries = document.querySelectorAll(".example-query");
      exampleQueries.forEach((query) => {
        if (event.detail.theme === "dark") {
          query.style.borderColor = "#495057";
          if (!query.classList.contains("btn-primary")) {
            query.style.color = "#f8f9fa";
          }
        } else {
          query.style.borderColor = "#ced4da";
          if (!query.classList.contains("btn-primary")) {
            query.style.color = "";
          }
        }
      });
    });

    /**
     * Update the status bar styling based on current theme
     * @param {string} theme - 'dark' or 'light'
     */
    function updateStatusBarTheme(theme) {
      const statusBar = document.querySelector(".monaco-status-bar");
      if (!statusBar) return;

      if (theme === "dark") {
        statusBar.style.backgroundColor = "#343a40";
        statusBar.style.borderColor = "#495057";
        statusBar.style.color = "#adb5bd";
      } else {
        statusBar.style.backgroundColor = "#f8f9fa";
        statusBar.style.borderColor = "#ced4da";
        statusBar.style.color = "#6c757d";
      }
    }

    const tableName = document.getElementById("table_name").value;
    const columns = JSON.parse(document.getElementById("columns_data").value);

    // Register SQL completion providers
    monaco.languages.registerCompletionItemProvider("sql", {
      provideCompletionItems: function () {
        const suggestions = [];

        // Add table name suggestion
        suggestions.push({
          label: tableName,
          kind: monaco.languages.CompletionItemKind.Class,
          insertText: tableName,
          detail: "Table name",
        });

        // Add column name suggestions
        columns.forEach((col) => {
          suggestions.push({
            label: col.name,
            kind: monaco.languages.CompletionItemKind.Field,
            insertText: col.name,
            detail: `Column (${col.type})`,
          });
        });

        // Add common SQL keywords
        const keywords = [
          { label: "SELECT", insertText: "SELECT " },
          { label: "FROM", insertText: "FROM " },
          { label: "WHERE", insertText: "WHERE " },
          { label: "ORDER BY", insertText: "ORDER BY " },
          { label: "GROUP BY", insertText: "GROUP BY " },
          { label: "HAVING", insertText: "HAVING " },
          { label: "LIMIT", insertText: "LIMIT " },
          { label: "JOIN", insertText: "JOIN " },
          { label: "LEFT JOIN", insertText: "LEFT JOIN " },
          { label: "INNER JOIN", insertText: "INNER JOIN " },
        ];

        keywords.forEach((kw) => {
          suggestions.push({
            label: kw.label,
            kind: monaco.languages.CompletionItemKind.Keyword,
            insertText: kw.insertText,
          });
        });

        return { suggestions };
      },
    });

    // Handle form submission - transfer content to hidden input before submitting
    const sqlForm = document.getElementById("sql-query-form");
    sqlForm.addEventListener("submit", function (event) {
      event.preventDefault();
      const queryInput = document.getElementById("query-input");

      queryInput.value = editor.getValue();
      const statusInfo = document.querySelector(
        ".monaco-status-bar .status-info"
      );
      if (statusInfo) statusInfo.textContent = "Executing query...";

      this.submit();
    });

    const exampleQueries = document.querySelectorAll(".example-query");
    exampleQueries.forEach((example) => {
      example.style.cursor = "pointer";
      example.addEventListener("click", () => {
        const query = decodeHTMLEntities(example.textContent);
        editor.setValue(query);
        editor.focus();

        const statusInfo = document.querySelector(
          ".monaco-status-bar .status-info"
        );
        statusInfo.textContent = "Example query loaded";

        setTimeout(() => {
          const position = editor.getPosition();
          if (position) {
            statusInfo.textContent = `Ln ${position.lineNumber}, Col ${position.column}`;
          } else {
            statusInfo.textContent = "Ready";
          }
        }, 2000);
      });
    });

    // Setup editor keybindings if editor was initialized successfully
    editor.addCommand(
      monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter,
      function () {
        const queryValue = editor.getValue();
        const queryInput = document.getElementById("query-input");
        const sqlForm = document.getElementById("sql-query-form");

        queryInput.value = queryValue;

        // Update status to indicate submission
        const statusInfo = document.querySelector(
          ".monaco-status-bar .status-info"
        );
        if (statusInfo) statusInfo.textContent = "Executing query...";

        sqlForm.submit();
      }
    );

    // Add SELECT * action
    editor.addAction({
      id: "insert-select-all",
      label: "Insert SELECT * FROM statement",
      keybindings: [
        monaco.KeyMod.CtrlCmd | monaco.KeyMod.Alt | monaco.KeyCode.KeyS,
      ],
      run: function () {
        try {
          editor.trigger("keyboard", "type", {
            text: `SELECT * FROM ${tableName} LIMIT 100`,
          });
        } catch (error) {
          console.error("Error inserting SELECT statement:", error);
        }
        return null;
      },
    });

    // Add WHERE clause action
    editor.addAction({
      id: "insert-where",
      label: "Insert WHERE clause",
      keybindings: [
        monaco.KeyMod.CtrlCmd | monaco.KeyMod.Alt | monaco.KeyCode.KeyW,
      ],
      run: function () {
        editor.trigger("keyboard", "type", { text: " WHERE " });
        return null;
      },
    });

    // Add toggle table structure action
    editor.addAction({
      id: "toggle-table-structure",
      label: "Toggle Table Structure Reference",
      keybindings: [
        monaco.KeyMod.CtrlCmd | monaco.KeyMod.Alt | monaco.KeyCode.KeyT,
      ],
      run: function () {
        const tableStructureContent = document.getElementById(
          "tableStructureContent"
        );
        if (!tableStructureContent) {
          throw new Error("Table structure content element not found");
        }

        bootstrap.Collapse.getOrCreateInstance(tableStructureContent).toggle();
        return null;
      },
    });

    const statusBarDiv = document.createElement("div");
    statusBarDiv.className = "monaco-status-bar";
    statusBarDiv.innerHTML = `<div class="status-info">Ready</div>
                            <div class="column-info">Table: ${tableName} (${columns.length} columns)</div>`;
    editorContainer.after(statusBarDiv);

    // Apply initial theme to status bar
    updateStatusBarTheme(ThemeManager.getCurrentTheme());

    // Update status bar with cursor position
    editor.onDidChangeCursorPosition((e) => {
      const position = `Ln ${e.position.lineNumber}, Col ${e.position.column}`;
      const statusInfo = statusBarDiv.querySelector(".status-info");
      if (statusInfo) statusInfo.textContent = position;
    });

    // Focus the editor when page loads
    window.addEventListener("load", () => {
      editor.focus();
    });

    // Toggle icon when table structure collapses or expands
    const tableStructureContent = document.getElementById(
      "tableStructureContent"
    );

    tableStructureContent.addEventListener("show.bs.collapse", function () {
      const icon = document.querySelector("#tableStructureHeader button i");
      icon.classList.replace("bi-chevron-down", "bi-chevron-up");
    });

    tableStructureContent.addEventListener("hide.bs.collapse", function () {
      const icon = document.querySelector("#tableStructureHeader button i");
      icon.classList.replace("bi-chevron-up", "bi-chevron-down");
    });

    // Add error recovery mechanism
    window.addEventListener("error", function (e) {
      // Only handle Monaco editor related errors
      if (e.message.includes("monaco") || e.message.includes("editor")) {
        displayError(
          "query-container",
          "Editor Error",
          "An error occurred in the SQL editor",
          "Please refresh the page to restore full functionality"
        );
      }
    });

    // Global error handler for Monaco editor errors
    window.addEventListener("error", function (e) {
      // Only handle Monaco editor related errors
      if (e.message.includes("monaco") || e.message.includes("editor")) {
        displayError(
          "query-container",
          "Editor Error",
          "An error occurred in the SQL editor",
          "Please refresh the page to restore full functionality"
        );
      }
    });
  });
});
