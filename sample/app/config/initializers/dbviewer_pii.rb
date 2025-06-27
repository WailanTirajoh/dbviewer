Dbviewer.configure_pii do |pii|
  # User contact information
  pii.mask 'users.email', with: :email              # john.doe@example.com → jo***@example.com
  pii.mask 'users.phone', with: :phone              # 555-123-4567 → 55***67
  pii.mask 'users.first_name', with: :partial       # John → Jo***n (for GDPR compliance)
  pii.mask 'users.last_name', with: :partial        # Doe → D***e

  # Date of birth - show only year for analytics while protecting privacy
  pii.mask 'users.date_of_birth', with: ->(value) {
    return value if value.nil?

    begin
      date = Date.parse(value.to_s)
      "#{date.year}/***/**"  # 1990-05-15 → 1990/***/**
    rescue
      value
    end
  }
end
