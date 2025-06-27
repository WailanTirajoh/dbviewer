Dbviewer.configure do |config|
  # Enable/disable PII masking globally (default: true)
  # config.enable_pii_masking = true
end

# Configure PII masking rules
Dbviewer.configure_pii do |pii|
  # pii.mask "users.email", with: :email
  # pii.mask "customers.email_address", with: :email

  # # Custom masking with lambda/proc:
  # pii.mask "users.address", with: ->(value) {
  #   return value if value.nil?
  #   "#{value.split(' ').first} ***"  # Show only first word
  # }

  # # Define custom masking functions that can be reused:
  # pii.custom_mask :ip_mask, ->(value) {
  #   return value if value.nil?
  #   parts = value.split(".")
  #   return value if parts.length != 4
  #   "#{parts[0]}.#{parts[1]}.***.***.***"
  # }
  # pii.mask "logs.ip_address", with: :ip_mask
  # pii.mask "sessions.client_ip", with: :ip_mask
end
