document.addEventListener("DOMContentLoaded", () => {
  const tableName = document.getElementById("table_name")?.value;
  const deleteConfirmModal = document.getElementById("deleteConfirmModal");
  const recordDeleteForm = document.getElementById("recordDeleteForm");

  // === TOASTIFY UTIL ===
  const showToast = (message, type = "success") => {
    const icons = {
      success: "clipboard-check",
      info: "info-circle",
      danger: "exclamation-triangle",
      warning: "exclamation-diamond",
    };

    Toastify({
      text: `
        <span class="toast-icon">
          <i class="bi bi-${icons[type] || "info-circle"}"></i>
        </span>
        ${message}
      `,
      className: `toast-factory-bot toast-${type}`,
      duration: 3000,
      gravity: "bottom",
      position: "right",
      escapeMarkup: false,
      style: {
        animation:
          "slideInRight 0.3s ease-out, slideOutRight 0.3s ease-out 2.7s",
        background: type === "danger" ? "#dc3545" : undefined,
      },
    }).showToast();
  };

  // === SETUP DELETE MODAL ===
  const setupDeleteConfirmModal = (recordData, pkName, pkValue) => {
    if (!recordData || !pkValue)
      return console.error("Missing record data for delete confirmation");

    const infoDiv = document.getElementById("deleteRecordInfo");
    const idInput = document.getElementById("deleteRecordId");

    idInput.value = pkValue;
    recordDeleteForm.action = `${
      window.location.pathname
    }/records/${encodeURIComponent(pkValue)}`;
    infoDiv.innerHTML = `<div><strong>${pkName}:</strong> ${pkValue}</div>`;

    const importantFields = [
      "name",
      "title",
      "email",
      "username",
      "code",
      "reference",
    ];
    let count = 0;

    for (const key of Object.keys(recordData)) {
      if (count >= 3) break;
      const lowerKey = key.toLowerCase();
      if (
        key !== pkName &&
        importantFields.some((f) => lowerKey.includes(f)) &&
        recordData[key]
      ) {
        const fieldDiv = document.createElement("div");
        fieldDiv.className = "mt-1";
        fieldDiv.innerHTML = `<strong>${key}:</strong> ${recordData[key]}`;
        infoDiv.appendChild(fieldDiv);
        count++;
      }
    }
  };

  // === DELETE FROM DETAIL MODAL ===
  const detailDeleteBtn = document.getElementById("recordDetailDeleteBtn");
  if (detailDeleteBtn) {
    detailDeleteBtn.addEventListener("click", () => {
      const rows = document.querySelectorAll("#recordDetailTableBody tr");
      const recordData = {};

      rows.forEach((row) => {
        const [keyCell, valueCell] = row.querySelectorAll("td");
        if (keyCell && valueCell) {
          recordData[keyCell.textContent.trim()] = valueCell.textContent.trim();
        }
      });

      const pkName =
        Object.keys(recordData).find((k) => k.toLowerCase() === "id") ||
        Object.keys(recordData)[0];
      const pkValue = recordData[pkName];

      setupDeleteConfirmModal(recordData, pkName, pkValue);

      bootstrap.Modal.getInstance(
        document.getElementById("recordDetailModal")
      )?.hide();
      setTimeout(() => new bootstrap.Modal(deleteConfirmModal).show(), 500);
    });
  }

  // === DELETE FROM TABLE ROW ===
  document.querySelectorAll(".delete-record-btn").forEach((button) => {
    button.addEventListener("click", () => {
      const recordData = JSON.parse(button.dataset.recordData || "{}");
      const pkName =
        Object.keys(recordData).find((k) => k.toLowerCase() === "id") ||
        Object.keys(recordData)[0];
      const pkValue = recordData[pkName];
      setupDeleteConfirmModal(recordData, pkName, pkValue);
    });
  });

  // === FORM SUBMIT (DELETE) ===
  if (recordDeleteForm) {
    recordDeleteForm.addEventListener("submit", async (e) => {
      e.preventDefault();

      const form = e.target;
      const submitButton = document.querySelector(
        "#recordDeleteForm button[type='submit']"
      );
      const originalText = submitButton.innerHTML;
      const csrfToken = document.querySelector(
        'meta[name="csrf-token"]'
      )?.content;

      disableSubmitButton(submitButton);

      try {
        const response = await fetch(form.action, {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "X-CSRF-Token": csrfToken,
          },
          credentials: "same-origin",
        });

        const result = await response.json();

        if (!response.ok) {
          throw new Error(result?.error || "Failed to delete record");
        }

        showToast(result.message || "Record deleted successfully", "success");

        const modal = bootstrap.Modal.getInstance(deleteConfirmModal);
        modal.hide();

        setTimeout(() => window.location.reload(), 1000);
      } catch (error) {
        console.error("Delete Error:", error);
        showToast(error.message || "Unexpected error occurred", "danger");
      } finally {
        enableSubmitButton(submitButton, originalText);
      }
    });
  }

  // === BUTTON HELPERS ===
  function disableSubmitButton(button) {
    button.disabled = true;
  }

  function enableSubmitButton(button) {
    button.disabled = false;
  }
});
