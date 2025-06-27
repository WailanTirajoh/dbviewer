# PII (Personally Identifiable Information) Masking

DBViewer includes built-in support for masking sensitive data to protect user privacy while allowing developers to browse database contents.

## Overview

PII masking allows you to define rules for specific table columns that automatically mask sensitive data when displayed in the DBViewer interface. This helps ensure compliance with privacy regulations while maintaining the ability to debug and analyze your database structure.

## Configuration

Configure PII masking in your Rails initializer (e.g., `config/initializers/dbviewer.rb`):

```ruby
# Enable PII masking (enabled by default)
Dbviewer.configure do |config|
  config.enable_pii_masking = true
end

# Define masking rules
Dbviewer.configure_pii do |pii|
  # Built-in masking types
  pii.mask 'users.email', with: :email
  pii.mask 'users.phone', with: :phone
  pii.mask 'users.ssn', with: :ssn
  pii.mask 'payments.card_number', with: :credit_card
  pii.mask 'users.api_key', with: :full_redact

  # Custom masking with lambda
  pii.mask 'users.address', with: ->(value) {
    return value if value.nil?
    "#{value.split(' ').first} [REDACTED]"
  }

  # Define reusable custom masks
  pii.custom_mask :ip_mask, ->(value) {
    return value if value.nil?
    parts = value.split('.')
    "#{parts[0]}.#{parts[1]}.***.***.***"
  }

  pii.mask 'logs.ip_address', with: :ip_mask
end
```

## Built-in Masking Types

### `:email`

Masks email addresses while preserving domain information:

- `john.doe@example.com` → `jo***@example.com`

### `:phone`

Masks phone numbers keeping first and last digits:

- `+1234567890` → `+1***90`
- `555-123-4567` → `55***67`

### `:ssn`

Masks Social Security Numbers showing only last 4 digits:

- `123456789` → `***-**-6789`

### `:credit_card`

Masks credit card numbers showing only last 4 digits:

- `1234567890123456` → `****-****-****-3456`

### `:full_redact`

Completely redacts the value:

- `any_value` → `***REDACTED***`

### `:partial`

Partial masking (default behavior):

- `john_doe` → `jo***oe`
- `confidential` → `co***al`

## Custom Masking

### Inline Lambda/Proc

Define custom masking logic directly in the configuration:

```ruby
pii.mask 'users.salary', with: ->(value) {
  return value if value.nil?
  "$***,***"
}

pii.mask 'profiles.bio', with: ->(value) {
  return value if value.nil? || value.length <= 50
  "#{value[0..50]}... [TRUNCATED]"
}
```

### Reusable Custom Masks

Define custom masks that can be reused across multiple columns:

```ruby
# Define the custom mask
pii.custom_mask :date_year_only, ->(value) {
  return value if value.nil?
  begin
    date = Date.parse(value.to_s)
    "#{date.year}/***/**"
  rescue
    value
  end
}

# Use it on multiple columns
pii.mask 'users.birth_date', with: :date_year_only
pii.mask 'employees.hire_date', with: :date_year_only
```

## Column Specification Format

Specify columns using the format `'table_name.column_name'`:

```ruby
pii.mask 'users.email', with: :email          # users table, email column
pii.mask 'customer_profiles.phone', with: :phone  # customer_profiles table, phone column
```

## Disabling PII Masking

You can disable PII masking globally or for specific environments:

```ruby
# Disable globally
Dbviewer.configure do |config|
  config.enable_pii_masking = false
end

# Or conditionally
Dbviewer.configure do |config|
  config.enable_pii_masking = !Rails.env.development?
end
```

## Where Masking Applies

PII masking is applied in:

- Table data views (`/dbviewer/tables/:table_name`)
- SQL query results (`/dbviewer/tables/:table_name/query`)
- Record detail modals
- CSV exports (if enabled)

## Security Considerations

- PII masking is a display-level feature and doesn't modify your actual database data
- Masking rules are applied on the application server, not the database level
- Consider your environment's security requirements when configuring masking rules
- Test your masking rules thoroughly to ensure sensitive data is properly protected
- Remember that users with database access can still view unmasked data directly

## Error Handling

If a custom masking function raises an exception, DBViewer will:

1. Log a warning to the Rails logger
2. Display `***ERROR***` instead of the original value
3. Continue processing other values normally

## Examples by Use Case

### E-commerce Application

```ruby
Dbviewer.configure_pii do |pii|
  # Customer data
  pii.mask 'customers.email', with: :email
  pii.mask 'customers.phone', with: :phone
  pii.mask 'customers.first_name', with: :partial
  pii.mask 'customers.last_name', with: :partial

  # Payment data
  pii.mask 'payments.card_number', with: :credit_card
  pii.mask 'payments.billing_address', with: ->(addr) { addr ? "#{addr.split(',').first}, [REDACTED]" : addr }

  # Orders
  pii.mask 'orders.shipping_address', with: :partial
end
```

### SaaS Application

```ruby
Dbviewer.configure_pii do |pii|
  # User accounts
  pii.mask 'users.email', with: :email
  pii.mask 'users.api_key', with: :full_redact
  pii.mask 'users.password_digest', with: :full_redact

  # Organizations
  pii.mask 'organizations.billing_email', with: :email
  pii.mask 'organizations.webhook_secret', with: :full_redact

  # Audit logs
  pii.mask 'audit_logs.metadata', with: ->(value) {
    return value if value.nil?
    "[AUDIT DATA - #{value.to_s.length} chars]"
  }
end
```

### Healthcare Application

```ruby
Dbviewer.configure_pii do |pii|
  # Patient data - highly sensitive
  pii.mask 'patients.ssn', with: :ssn
  pii.mask 'patients.email', with: :email
  pii.mask 'patients.first_name', with: :full_redact
  pii.mask 'patients.last_name', with: :full_redact
  pii.mask 'patients.date_of_birth', with: :full_redact
  pii.mask 'patients.medical_record_number', with: :full_redact

  # Medical data
  pii.mask 'appointments.notes', with: :full_redact
  pii.mask 'prescriptions.details', with: :full_redact
end
```
