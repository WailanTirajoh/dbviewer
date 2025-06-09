import * as monaco from "https://cdn.jsdelivr.net/npm/monaco-editor@0.39.0/+esm";

// Helper function to decode HTML entities
function decodeHTMLEntities(text) {
  const textarea = document.createElement("textarea");
  textarea.innerHTML = text;
  return textarea.value;
}

// Get initial query value from a data attribute to avoid string escaping issues
const initialQueryEncoded = document
  .getElementById("monaco-editor")
  .getAttribute("data-initial-query");
const initialQuery = decodeHTMLEntities(initialQueryEncoded);

// Determine initial theme based on document theme
const initialTheme =
  document.documentElement.getAttribute("data-bs-theme") === "dark"
    ? "vs-dark"
    : "vs";

// Initialize Monaco Editor with SQL syntax highlighting
const editor = monaco.editor.create(document.getElementById("monaco-editor"), {
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
  const editorContainer = document.querySelector(".monaco-editor-container");
  if (editorContainer) {
    editorContainer.style.borderColor =
      event.detail.theme === "dark" ? "#495057" : "#ced4da";
  }

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

// Set up SQL intellisense with table/column completions
const tableName = document.getElementById("table_name").value;
const columns = JSON.parse(document.getElementById("columns_data").value);

// Register SQL completion providers
monaco.languages.registerCompletionItemProvider("sql", {
  provideCompletionItems: function (model, position) {
    const textUntilPosition = model.getValueInRange({
      startLineNumber: position.lineNumber,
      startColumn: 1,
      endLineNumber: position.lineNumber,
      endColumn: position.column,
    });

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
document
  .getElementById("sql-query-form")
  .addEventListener("submit", function (event) {
    // Stop the form from submitting immediately
    event.preventDefault();

    // Get the query value from the editor and set it to the hidden input
    const queryValue = editor.getValue();
    document.getElementById("query-input").value = queryValue;

    // Now manually submit the form
    this.submit();
  });

// Make example queries clickable
document.querySelectorAll(".example-query").forEach((example) => {
  example.style.cursor = "pointer";
  example.addEventListener("click", () => {
    const query = decodeHTMLEntities(example.textContent);
    editor.setValue(query);
    editor.focus();
  });
});

// Setup editor keybindings
editor.addCommand(monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter, function () {
  // Get the query value from the editor and set it to the hidden input
  const queryValue = editor.getValue();
  document.getElementById("query-input").value = queryValue;

  // Submit the form
  document.getElementById("sql-query-form").submit();
});

// Add keyboard shortcuts for common SQL statements
editor.addAction({
  id: "insert-select-all",
  label: "Insert SELECT * FROM statement",
  keybindings: [
    monaco.KeyMod.CtrlCmd | monaco.KeyMod.Alt | monaco.KeyCode.KeyS,
  ],
  run: function () {
    editor.trigger("keyboard", "type", {
      text: `SELECT * FROM ${tableName} LIMIT 100`,
    });
    return null;
  },
});

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

editor.addAction({
  id: "toggle-table-structure",
  label: "Toggle Table Structure Reference",
  keybindings: [
    monaco.KeyMod.CtrlCmd | monaco.KeyMod.Alt | monaco.KeyCode.KeyT,
  ],
  run: function () {
    // Use Bootstrap's collapse API to toggle
    bootstrap.Collapse.getOrCreateInstance(
      document.getElementById("tableStructureContent")
    ).toggle();
    return null;
  },
});

// Create a status bar showing cursor position and columns info
const statusBarDiv = document.createElement("div");
statusBarDiv.className = "monaco-status-bar";
statusBarDiv.innerHTML = `<div class="status-info">Ready</div>
                          <div class="column-info">Table: ${tableName} (${columns.length} columns)</div>`;
document.getElementById("monaco-editor").after(statusBarDiv);

// Apply initial theme to status bar
const currentTheme =
  document.documentElement.getAttribute("data-bs-theme") || "light";
updateStatusBarTheme(currentTheme);

// Update status bar with cursor position
editor.onDidChangeCursorPosition((e) => {
  const position = `Ln ${e.position.lineNumber}, Col ${e.position.column}`;
  statusBarDiv.querySelector(".status-info").textContent = position;
});

// Focus the editor when page loads
window.addEventListener("load", () => {
  editor.focus();
});

// Toggle icon when table structure collapses or expands
document
  .getElementById("tableStructureContent")
  .addEventListener("show.bs.collapse", function () {
    document
      .querySelector("#tableStructureHeader button i")
      .classList.replace("bi-chevron-down", "bi-chevron-up");
  });

document
  .getElementById("tableStructureContent")
  .addEventListener("hide.bs.collapse", function () {
    document
      .querySelector("#tableStructureHeader button i")
      .classList.replace("bi-chevron-up", "bi-chevron-down");
  });
