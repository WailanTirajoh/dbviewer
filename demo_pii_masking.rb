#!/usr/bin/env ruby

# Demo script showing PII masking functionality
# Run: ruby demo_pii_masking.rb

require_relative 'lib/dbviewer/configuration'
require_relative 'lib/dbviewer/data_privacy/pii_masker'

# Mock the Dbviewer module for the demo
module Dbviewer
  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end
  end
end

puts "=== DBViewer PII Masking Demo ==="
puts

# Create a configuration instance
config = Dbviewer::Configuration.new

# Configure some PII rules
config.pii_rules = {
  'users.email' => :email,
  'users.phone' => :phone,
  'users.ssn' => :ssn,
  'payments.card_number' => :credit_card,
  'users.api_key' => :full_redact,
  'users.username' => :partial,
  'users.salary' => ->(value) { value ? '$***,***' : value }
}

config.custom_pii_masks = {
  ip_mask: ->(value) {
    return value if value.nil?
    parts = value.split('.')
    return value if parts.length != 4
    "#{parts[0]}.#{parts[1]}.***.***.***"
  }
}

config.pii_rules['logs.ip_address'] = :ip_mask

# Temporarily set this configuration
original_config = Dbviewer.configuration
Dbviewer.instance_variable_set(:@configuration, config)

puts "Sample data masking results:"
puts

test_data = [
  [ 'users', 'email', 'john.doe@example.com' ],
  [ 'users', 'email', 'a@test.com' ],
  [ 'users', 'phone', '+1-555-123-4567' ],
  [ 'users', 'phone', '1234567890' ],
  [ 'users', 'ssn', '123-45-6789' ],
  [ 'users', 'ssn', '123456789' ],
  [ 'payments', 'card_number', '1234-5678-9012-3456' ],
  [ 'payments', 'card_number', '1234567890123456' ],
  [ 'users', 'api_key', 'sk_live_abcdef123456789' ],
  [ 'users', 'username', 'john_doe_developer' ],
  [ 'users', 'salary', '85000' ],
  [ 'logs', 'ip_address', '192.168.1.100' ],
  [ 'users', 'name', 'John Doe' ] # No masking rule
]

test_data.each do |table, column, value|
  masked_value = Dbviewer::DataPrivacy::PiiMasker.mask_value(value, table, column)
  status = masked_value == value ? "[NO MASK]" : "[MASKED]"
  puts "#{table}.#{column.ljust(12)} | #{value.ljust(25)} → #{masked_value.ljust(25)} #{status}"
end

puts
puts "=== Custom Masking Example ==="
puts

# Show nil handling
nil_result = Dbviewer::DataPrivacy::PiiMasker.mask_value(nil, 'users', 'email')
puts "Nil value handling: nil → #{nil_result.inspect}"

puts
puts "=== PII Masking Disabled ==="
puts

# Show behavior when disabled
config.enable_pii_masking = false
disabled_result = Dbviewer::DataPrivacy::PiiMasker.mask_value('test@example.com', 'users', 'email')
puts "When disabled: test@example.com → #{disabled_result}"

# Restore original config
Dbviewer.instance_variable_set(:@configuration, original_config)

puts
puts "Demo completed! ✅"
