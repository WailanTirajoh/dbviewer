
document.addEventListener('DOMContentLoaded', function() {
  // Add connection form validation
  const forms = document.querySelectorAll('.needs-validation');
  
  Array.from(forms).forEach(form => {
    form.addEventListener('submit', event => {
      if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
      }
      
      form.classList.add('was-validated');
    }, false);
  });
  
  // Handle connection test
  const testButtons = document.querySelectorAll('.test-connection-btn');
  
  Array.from(testButtons).forEach(button => {
    button.addEventListener('click', async function(event) {
      event.preventDefault();
      const connectionKey = this.dataset.connectionKey;
      const statusElement = document.getElementById(`connection-status-${connectionKey}`);
      
      if (!statusElement) return;
      
      statusElement.innerHTML = '<i class="bi bi-arrow-repeat spin me-1"></i> Testing connection...';
      statusElement.classList.remove('text-success', 'text-danger');
      
      try {
        const response = await fetch(`/dbviewer/api/connections/${connectionKey}/test`, {
          method: 'GET',
          headers: {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest'
          }
        });
        
        const data = await response.json();
        
        if (data.success) {
          statusElement.innerHTML = '<i class="bi bi-check-circle-fill me-1"></i> Connection successful';
          statusElement.classList.add('text-success');
        } else {
          statusElement.innerHTML = `<i class="bi bi-x-circle-fill me-1"></i> ${data.error || 'Connection failed'}`;
          statusElement.classList.add('text-danger');
        }
      } catch (error) {
        statusElement.innerHTML = '<i class="bi bi-x-circle-fill me-1"></i> Error testing connection';
        statusElement.classList.add('text-danger');
      }
    });
  });
});

// Auto-generate connection key from name
function setupConnectionKeyGenerator() {
  const nameInput = document.getElementById('connection_name');
  const keyInput = document.getElementById('connection_key');
  
  if (nameInput && keyInput) {
    nameInput.addEventListener('input', function() {
      keyInput.value = this.value
        .toLowerCase()
        .replace(/\s+/g, '_')
        .replace(/[^a-z0-9_]/g, '');
    });
  }
}
