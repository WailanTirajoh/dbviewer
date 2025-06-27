# Example DBViewer PII Configuration
#
# This file shows how to configure PII (Personally Identifiable Information) masking
# in DBViewer to protect sensitive data in your database views.
#
# Place this configuration in your Rails initializer file (e.g., config/initializers/dbviewer.rb)

Dbviewer.configure do |config|
  # Enable/disable PII masking globally (default: true)
  config.enable_pii_masking = true

  # Other DBViewer configurations...
  # config.default_per_page = 20
  # config.enable_data_export = false
end

# Configure PII masking rules
Dbviewer.configure_pii do |pii|
  # Built-in masking types:

  # Email masking: john.doe@example.com -> jo***@example.com
  pii.mask "users.email", with: :email
  pii.mask "customers.email_address", with: :email

  # Phone masking: +1234567890 -> +1***90
  pii.mask "users.phone", with: :phone
  pii.mask "profiles.mobile_number", with: :phone

  # Social Security Number masking: 123456789 -> ***-**-6789
  pii.mask "users.ssn", with: :ssn
  pii.mask "employees.social_security", with: :ssn

  # Credit card masking: 1234567890123456 -> ****-****-****-3456
  pii.mask "payments.card_number", with: :credit_card

  # Full redaction: any_value -> ***REDACTED***
  pii.mask "users.api_key", with: :full_redact
  pii.mask "accounts.secret_token", with: :full_redact

  # Partial masking (default): john_doe -> jo***oe
  pii.mask "users.username", with: :partial

  # Custom masking with lambda/proc:
  pii.mask "users.address", with: ->(value) {
    return value if value.nil?
    "#{value.split(' ').first} ***"  # Show only first word
  }

  # Define custom masking functions that can be reused:
  pii.custom_mask :ip_mask, ->(value) {
    return value if value.nil?
    parts = value.split(".")
    return value if parts.length != 4
    "#{parts[0]}.#{parts[1]}.***.***.***"
  }

  # Use custom mask:
  pii.mask "logs.ip_address", with: :ip_mask
  pii.mask "sessions.client_ip", with: :ip_mask

  # More examples:

  # Customer data
  pii.mask "customers.first_name", with: :partial
  pii.mask "customers.last_name", with: :partial
  pii.mask "customers.date_of_birth", with: ->(value) {
    return value if value.nil?
    date = Date.parse(value.to_s) rescue nil
    date ? "#{date.year}/***/**" : value
  }

  # Employee data
  pii.mask "employees.salary", with: ->(value) { value ? "$***,***" : value }
  pii.mask "employees.bank_account", with: :full_redact

  # User profiles
  pii.mask "profiles.biography", with: ->(value) {
    return value if value.nil? || value.length <= 50
    "#{value[0..50]}... [TRUNCATED FOR PRIVACY]"
  }

  # System logs with PII
  pii.mask "audit_logs.user_data", with: :full_redact
  pii.mask "error_logs.request_params", with: ->(value) {
    # Redact JSON containing potential PII
    return value if value.nil?
    begin
      JSON.parse(value)
      "{ [REDACTED JSON DATA] }"
    rescue
      value
    end
  }
end

# You can also disable PII masking globally:
# Dbviewer.configure_pii do |pii|
#   pii.enabled = false
# end
