// Record Creation Modal
document.addEventListener("DOMContentLoaded", function () {
  const addRecordButton = document.getElementById("floatingAddRecordBtn");
  if (!addRecordButton) return;

  const tableName = document.getElementById("table_name").value;
  const newRecordModal = document.getElementById("newRecordModal");

  addRecordButton.addEventListener("click", async function () {
    const modal = new bootstrap.Modal(newRecordModal);
    const modalBody = newRecordModal.querySelector(".modal-content");

    // Show loading state
    modalBody.innerHTML = `
      <div class="modal-body text-center py-5">
        <div class="spinner-border text-primary" role="status">
          <span class="visually-hidden">Loading...</span>
        </div>
        <p class="mt-3">Loading form...</p>
      </div>
    `;
    modal.show();

    try {
      const response = await fetch(`/dbviewer/tables/${tableName}/new_record`);
      const html = await response.text();
      modalBody.innerHTML = html;
      initializeFormElements();
    } catch (error) {
      modalBody.innerHTML = `
        <div class="modal-header">
          <h5 class="modal-title">Error</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>
        <div class="modal-body">
          <div class="alert alert-danger">
            Failed to load form: ${error.message}
          </div>
        </div>
        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
        </div>
      `;
    }
  });

  newRecordModal.addEventListener("submit", async function (event) {
    const form = event.target;
    if (form.id !== "newRecordForm") return;

    event.preventDefault();

    const submitButton = document.getElementById("createRecordButton");
    const originalText = submitButton.innerHTML;
    submitButton.disabled = true;
    submitButton.innerHTML =
      '<span class="spinner-border spinner-border-sm" role="status" aria-hidden="true"></span> Creating...';

    const formData = new FormData(form);

    try {
      const response = await fetch(form.action, {
        method: "POST",
        body: formData,
        headers: {
          "X-Requested-With": "XMLHttpRequest",
        },
      });

      if (response.ok) {
        const data = await response.json();
        const modal = bootstrap.Modal.getInstance(newRecordModal);
        modal.hide();

        Toastify({
          text: `<span class="toast-icon"><i class="bi bi-clipboard-check"></i></span> Record created successfully!`,
          className: "toast-factory-bot",
          duration: 3000,
          gravity: "bottom",
          position: "right",
          escapeMarkup: false,
          style: {
            animation:
              "slideInRight 0.3s ease-out, slideOutRight 0.3s ease-out 2.7s",
          },
        }).showToast();

        setTimeout(() => {
          window.location.reload();
        }, 1000);
      } else {
        const html = await response.text();
        const modalContent = newRecordModal.querySelector(".modal-content");
        modalContent.innerHTML = html;
        initializeFormElements();
      }
    } catch (error) {
      const errorDiv = document.createElement("div");
      errorDiv.className = "alert alert-danger";
      errorDiv.textContent = `Error: ${error.message}`;
      form.prepend(errorDiv);
    } finally {
      submitButton.disabled = false;
      submitButton.innerHTML = originalText;
    }
  });
});

// Initialize Select2 dropdowns and other form elements
function initializeFormElements() {
  if (typeof $.fn.select2 !== "undefined") {
    // Use jquery select2 for now, maybe we can change the dependency later
    $(".select2-dropdown").select2({
      dropdownParent: $("#newRecordModal"),
      theme: "bootstrap-5",
      width: "100%",
    });
  }
}
