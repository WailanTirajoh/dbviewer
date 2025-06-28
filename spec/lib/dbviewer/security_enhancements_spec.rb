require 'rails_helper'

RSpec.describe "DBViewer Security Enhancements" do
  describe "Query Operations Bug Fix" do
    it "should use the correct parameter in execute_query" do
      # Test that the execute_query method uses the query parameter
      # instead of the instance variable @query
      query_operations = Class.new do
        include RSpec::Mocks::ExampleMethods
        include Dbviewer::DatabaseOperations::QueryOperations

        def database_manager
          @database_manager ||= double("database_manager")
        end

        def flash
          @flash ||= double("flash", now: {})
        end
      end.new

      test_query = "SELECT * FROM users LIMIT 10"

      expect(query_operations.database_manager).to receive(:execute_query).with(test_query)
      query_operations.execute_query(test_query)
    end
  end

  describe "Enhanced SQL Injection Detection" do
    before do
      # Enable enhanced SQL protection for these tests
      configuration = instance_double(Dbviewer::Configuration, enhanced_sql_protection: true)
      allow(Dbviewer).to receive(:configuration).and_return(configuration)
    end

    describe "new injection patterns" do
      [
        "SELECT * FROM users WHERE id = 1; WAITFOR DELAY '00:00:05'",
        "SELECT BENCHMARK(1000000, MD5('test'))",
        "SELECT * FROM information_schema.tables",
        "SELECT * FROM mysql.user",
        "SELECT IF(1=1, SLEEP(5), 0)",
        "SELECT EXTRACTVALUE(1, CONCAT(0x7e, version(), 0x7e))"
      ].each do |malicious_query|
        it "detects injection in: #{malicious_query[0, 50]}#{malicious_query.length > 50 ? '...' : ''}" do
          expect(Dbviewer::Validator::Sql.safe_query?(malicious_query)).to be false
        end
      end
    end

    describe "new suspicious patterns" do
      [
        "SELECT CHAR(65,68,77,73,78)",
        "SELECT ASCII('A')",
        "SELECT SUBSTRING(version(), 1, 1)",
        "SELECT /*! UNION */ * FROM users",
        "SELECT * FROM users WHERE id = 1 UNION SELECT * FROM users UNION SELECT * FROM orders"
      ].each do |suspicious_query|
        it "detects suspicious pattern in: #{suspicious_query[0, 50]}#{suspicious_query.length > 50 ? '...' : ''}" do
          expect(Dbviewer::Validator::Sql.safe_query?(suspicious_query)).to be false
        end
      end
    end

    describe "legitimate queries" do
      [
        "SELECT * FROM users",
        "SELECT id, name FROM users WHERE created_at > '2024-01-01'",
        "SELECT COUNT(*) FROM orders",
        "SELECT u.name, o.total FROM users u JOIN orders o ON u.id = o.user_id"
      ].each do |safe_query|
        it "allows legitimate query: #{safe_query[0, 50]}#{safe_query.length > 50 ? '...' : ''}" do
          expect(Dbviewer::Validator::Sql.safe_query?(safe_query)).to be true
        end
      end
    end
  end

  describe "Input Sanitization" do
    let(:query_operations) do
      Class.new do
        include RSpec::Mocks::ExampleMethods
        include Dbviewer::DatabaseOperations::QueryOperations

        def database_manager
          @database_manager ||= double("database_manager",
            connection: double("connection", quote_table_name: ->(name) { "`#{name}`" })
          )
        end

        def flash
          @flash ||= double("flash", now: {})
        end

        # Expose private method for testing
        def test_sanitize_query_input(query)
          sanitize_query_input(query)
        end
      end.new
    end

    it "removes null bytes from input" do
      malicious_input = "SELECT * FROM users\x00; DROP TABLE users;"
      sanitized = query_operations.test_sanitize_query_input(malicious_input)
      expect(sanitized).not_to include("\x00")
    end

    it "truncates overly long queries" do
      long_query = "SELECT * FROM users WHERE name = '#{'A' * 10000}'"
      sanitized = query_operations.test_sanitize_query_input(long_query)
      expect(sanitized.length).to be <= 10000
    end

    it "strips whitespace" do
      query_with_whitespace = "  SELECT * FROM users  "
      sanitized = query_operations.test_sanitize_query_input(query_with_whitespace)
      expect(sanitized).to eq("SELECT * FROM users")
    end

    it "handles nil input gracefully" do
      sanitized = query_operations.test_sanitize_query_input(nil)
      expect(sanitized).to be_nil
    end
  end
end
