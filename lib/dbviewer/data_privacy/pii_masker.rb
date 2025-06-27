module Dbviewer
  module DataPrivacy
    class PiiMasker
      BUILT_IN_MASKS = {
        email: ->(value) { mask_email(value) },
        phone: ->(value) { mask_phone(value) },
        credit_card: ->(value) { mask_credit_card(value) },
        ssn: ->(value) { mask_ssn(value) },
        full_redact: ->(value) { value ? "***REDACTED***" : value },
        partial: ->(value) { mask_partial(value) }
      }.freeze

      def self.mask_value(value, table_name, column_name)
        return value unless should_mask?(table_name, column_name)

        rule = get_masking_rule(table_name, column_name)
        apply_mask(value, rule)
      end

      private

      def self.should_mask?(table_name, column_name)
        return false unless Dbviewer.configuration.enable_pii_masking
        return false if Dbviewer.configuration.pii_rules.empty?

        key = "#{table_name}.#{column_name}"
        Dbviewer.configuration.pii_rules.key?(key)
      end

      def self.get_masking_rule(table_name, column_name)
        key = "#{table_name}.#{column_name}"
        Dbviewer.configuration.pii_rules[key]
      end

      def self.apply_mask(value, rule)
        return value if value.nil?

        case rule
        when Symbol
          apply_built_in_mask(value, rule)
        when Proc
          rule.call(value)
        else
          apply_built_in_mask(value, :partial)
        end
      rescue => e
        Rails.logger.warn("PII masking failed for rule #{rule}: #{e.message}")
        "***ERROR***"
      end

      def self.apply_built_in_mask(value, mask_type)
        mask_proc = BUILT_IN_MASKS[mask_type]
        if mask_proc
          mask_proc.call(value)
        else
          # Check if it's a custom mask
          custom_mask = Dbviewer.configuration.custom_pii_masks[mask_type]
          if custom_mask && custom_mask.respond_to?(:call)
            custom_mask.call(value)
          else
            mask_partial(value)
          end
        end
      end

      def self.mask_email(value)
        return value unless value.to_s.include?("@")

        parts = value.to_s.split("@")
        username = parts[0]
        domain = parts[1]

        if username.length <= 1
          masked_username = "*"
        elsif username.length <= 2
          masked_username = username
        else
          masked_username = "#{username[0..1]}***"
        end

        "#{masked_username}@#{domain}"
      end

      def self.mask_phone(value)
        # Remove all non-digit characters
        digits = value.to_s.gsub(/\D/, "")
        return value if digits.length < 4

        # Keep first and last 2 digits, mask the middle
        if digits.length <= 6
          "#{digits[0]}#{'*' * (digits.length - 2)}#{digits[-1]}"
        else
          "#{digits[0..1]}#{'*' * 3}#{digits[-2..-1]}"
        end
      end

      def self.mask_credit_card(value)
        digits = value.to_s.gsub(/\D/, "")
        return value if digits.length < 4

        # Show last 4 digits only
        "****-****-****-#{digits[-4..-1]}"
      end

      def self.mask_ssn(value)
        digits = value.to_s.gsub(/\D/, "")
        return value if digits.length != 9

        # Show last 4 digits only
        "***-**-#{digits[-4..-1]}"
      end

      def self.mask_partial(value)
        str = value.to_s
        return str if str.length <= 2

        if str.length <= 4
          "#{str[0]}#{'*' * (str.length - 2)}#{str[-1]}"
        else
          "#{str[0..1]}#{'*' * 3}#{str[-2..-1]}"
        end
      end
    end
  end
end
