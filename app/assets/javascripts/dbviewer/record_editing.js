document.addEventListener("DOMContentLoaded", function () {
  const tableName = document.getElementById("table_name")?.value;
  if (!tableName) return;

  // Handle edit button in record detail modal
  const recordDetailEditBtn = document.getElementById("recordDetailEditBtn");
  if (recordDetailEditBtn) {
    recordDetailEditBtn.addEventListener("click", () => {
      const recordData = extractRecordDataFromDetailModal();
      const primaryKeyValue = extractPrimaryKeyValue(recordData);
      loadEditForm(primaryKeyValue);
    });
  }

  // Handle edit buttons in table rows
  document.querySelectorAll(".edit-record-btn").forEach((button) => {
    button.addEventListener("click", () => {
      const recordData = JSON.parse(button.dataset.recordData || "{}");
      const primaryKeyValue = extractPrimaryKeyValue(recordData);
      loadEditForm(primaryKeyValue);
    });
  });

  function extractRecordDataFromDetailModal() {
    const tableBody = document.getElementById("recordDetailTableBody");
    const rows = tableBody?.querySelectorAll("tr") || [];
    const recordData = {};

    rows.forEach((row) => {
      const cells = row.querySelectorAll("td");
      if (cells.length >= 2) {
        const columnName = cells[0].textContent.trim();
        const cellValue =
          cells[1].textContent.trim() === "NULL"
            ? ""
            : cells[1].textContent.trim();
        recordData[columnName] = cellValue;
      }
    });
    return recordData;
  }

  function extractPrimaryKeyValue(recordData) {
    const primaryKey =
      Object.keys(recordData).find((key) => key.toLowerCase() === "id") ||
      Object.keys(recordData)[0];
    return recordData[primaryKey];
  }

  async function loadEditForm(recordId) {
    const modal = document.getElementById("editRecordModal");
    const modalBody = modal.querySelector(".modal-content");
    const bsModal = new bootstrap.Modal(modal);

    modalBody.innerHTML = `
      <div class="modal-body text-center py-5">
        <div class="spinner-border text-primary" role="status"></div>
        <p class="mt-3">Loading edit form...</p>
      </div>
    `;

    bsModal.show();

    try {
      const response = await fetch(
        `${window.location.pathname}/records/${encodeURIComponent(
          recordId
        )}/edit`
      );
      if (!response.ok) throw new Error("Failed to load form");

      const html = await response.text();
      modalBody.innerHTML = html;

      initializeEditFormElements();
      document
        .getElementById("editRecordForm")
        ?.addEventListener("submit", handleEditFormSubmit);
    } catch (error) {
      modalBody.innerHTML = `
        <div class="modal-header">
          <h5 class="modal-title">Error</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>
        <div class="modal-body">
          <div class="alert alert-danger">${error.message}</div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      `;
    }
  }

  function initializeEditFormElements() {
    if (typeof $.fn.select2 !== "undefined") {
      $(".select2-dropdown").select2({
        dropdownParent: $("#editRecordModal"),
        theme: "bootstrap-5",
        width: "100%",
      });
    }

    if (typeof flatpickr !== "undefined") {
      flatpickr(".datetime-picker", {
        enableTime: true,
        dateFormat: "Y-m-d H:i:S",
        time_24hr: true,
        wrap: true,
      });

      flatpickr(".date-picker", {
        dateFormat: "Y-m-d",
        wrap: true,
      });
    }
  }

  async function handleEditFormSubmit(event) {
    event.preventDefault();

    const form = event.target;
    const submitButton = document.getElementById("updateRecordButton");
    const originalText = submitButton?.innerHTML;
    const formData = new FormData(form);
    const csrfToken = document.querySelector(
      'meta[name="csrf-token"]'
    )?.content;

    disableSubmitButton(submitButton, "Updating...");

    try {
      const response = await fetch(form.action, {
        method: form.method,
        body: formData,
        headers: { "X-CSRF-Token": csrfToken },
        credentials: "same-origin",
      });

      const result = await response.json();

      if (!response.ok)
        throw new Error(
          result?.messages?.join(", ") || "Failed to update record"
        );

      bootstrap.Modal.getInstance(
        document.getElementById("editRecordModal")
      )?.hide();
      showToast(result.message || "Record updated successfully");
      setTimeout(() => window.location.reload(), 1000);
    } catch (error) {
      showToast(error.message, "danger");
    } finally {
      enableSubmitButton(submitButton, originalText);
    }
  }

  function disableSubmitButton(button, loadingText) {
    if (!button) return;
    button.disabled = true;
    button.innerHTML = `<span class="spinner-border spinner-border-sm me-2"></span>${loadingText}`;
  }

  function enableSubmitButton(button, originalText) {
    if (!button) return;
    button.disabled = false;
    button.innerHTML = originalText;
  }

  function showToast(message, type = "success") {
    Toastify({
      text: `<span class="toast-icon"><i class="bi bi-${
        type === "success" ? "clipboard-check" : "exclamation-triangle"
      }"></i></span> ${message}`,
      className: "toast-factory-bot",
      duration: 3000,
      gravity: "bottom",
      position: "right",
      escapeMarkup: false,
      style: {
        animation: `slideInRight 0.3s ease-out, slideOutRight 0.3s ease-out 2.7s`,
        background: type === "danger" ? "#dc3545" : undefined,
      },
    }).showToast();
  }
});
