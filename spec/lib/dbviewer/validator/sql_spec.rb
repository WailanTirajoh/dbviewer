# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dbviewer::Validator::Sql do
  # Shared examples for testing SQL validation
  shared_examples "a safe SQL query" do |query_description|
    it "passes validation" do
      expect(described_class.safe_query?(sql_query)).to be true
    end

    it "successfully validates" do
      expect { described_class.validate!(sql_query) }.not_to raise_error
    end
  end

  shared_examples "an unsafe SQL query" do |expected_error_pattern|
    it "fails validation" do
      expect(described_class.safe_query?(sql_query)).to be false
    end

    it "raises SecurityError when validated" do
      expect { described_class.validate!(sql_query) }
        .to raise_error(SecurityError, expected_error_pattern)
    end
  end

  describe '.safe_query?' do
    # Group 1: Basic Query Structure Validation
    context 'with basic validation rules' do
      context 'for nil or empty queries' do
        let(:sql_query) { nil }
        it_behaves_like "an unsafe SQL query", "Empty query is not allowed"

        context 'with empty string' do
          let(:sql_query) { '' }
          it_behaves_like "an unsafe SQL query", "Empty query is not allowed"
        end

        context 'with whitespace only' do
          let(:sql_query) { '   ' }
          it_behaves_like "an unsafe SQL query", "Empty query is not allowed"
        end
      end

      context 'for query length limits' do
        let(:sql_query) { 'SELECT * FROM users WHERE name = ' + '"' + 'a' * 10000 + '"' }
        it_behaves_like "an unsafe SQL query", /Query exceeds maximum allowed length/
      end

      context 'for queries that do not start with SELECT' do
        let(:sql_query) { 'FROM users SELECT *' }
        it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
      end
    end

    # Group 2: Valid SELECT Queries
    context 'with valid SELECT queries' do
      context 'for simple SELECT queries' do
        [
          'SELECT * FROM users',
          'SELECT id, name FROM products',
          'SELECT COUNT(*) FROM orders'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "a safe SQL query"
          end
        end
      end

      context 'with WHERE clauses' do
        [
          'SELECT * FROM users WHERE id = 1',
          'SELECT name FROM products WHERE price > 100',
          'SELECT * FROM orders WHERE status = "pending"'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "a safe SQL query"
          end
        end
      end

      context 'with JOINs' do
        [
          'SELECT u.name, p.title FROM users u JOIN posts p ON u.id = p.user_id',
          'SELECT * FROM orders o LEFT JOIN customers c ON o.customer_id = c.id'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "a safe SQL query"
          end
        end
      end

      context 'with ORDER BY and GROUP BY' do
        [
          'SELECT * FROM users ORDER BY name',
          'SELECT COUNT(*) FROM orders GROUP BY status',
          'SELECT status, COUNT(*) FROM orders GROUP BY status HAVING COUNT(*) > 5'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "a safe SQL query"
          end
        end
      end

      context 'with subqueries' do
        [
          'SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE amount > 1000)',
          'SELECT * FROM products WHERE price > (SELECT AVG(price) FROM products)'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "a safe SQL query"
          end
        end
      end

      context 'with advanced SQL features' do
        context 'with window functions' do
          let(:sql_query) { 'SELECT name, ROW_NUMBER() OVER (ORDER BY created_at) FROM users' }
          it_behaves_like "a safe SQL query"
        end

        context 'with UNION' do
          let(:sql_query) { 'SELECT name FROM users UNION SELECT company_name FROM companies' }
          it_behaves_like "a safe SQL query"
        end

        context 'with CTEs (WITH clauses)' do
          let(:sql_query) { 'WITH top_users AS (SELECT * FROM users LIMIT 10) SELECT * FROM top_users' }
          it_behaves_like "a safe SQL query"
        end

        context 'with CASE statements' do
          let(:sql_query) { 'SELECT name, CASE WHEN age >= 18 THEN "adult" ELSE "minor" END FROM users' }
          it_behaves_like "a safe SQL query"
        end

        context 'with string functions' do
          [
            'SELECT UPPER(name) FROM users',
            'SELECT SUBSTRING(description, 1, 100) FROM products'
          ].each do |query|
            context "with query: #{query.inspect}" do
              let(:sql_query) { query }
              it_behaves_like "a safe SQL query"
            end
          end
        end

        context 'with date functions' do
          [
            'SELECT * FROM orders WHERE created_at >= DATE("2023-01-01")',
            'SELECT STRFTIME("%Y", created_at) FROM users'
          ].each do |query|
            context "with query: #{query.inspect}" do
              let(:sql_query) { query }
              it_behaves_like "a safe SQL query"
            end
          end
        end
      end

      context 'with database-specific syntax' do
        [
          'SELECT * FROM users LIMIT 10 OFFSET 5', # PostgreSQL
          'SELECT * FROM users LIMIT 5, 10',       # MySQL
          'SELECT * FROM users WHERE name GLOB "A*"' # SQLite
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "a safe SQL query"
          end
        end
      end
    end

    # Group 3: Invalid Queries - Data Modification
    context 'with data modification queries' do
      context 'for INSERT statements' do
        [
          'INSERT INTO users (name) VALUES ("John")',
          'INSERT INTO products SELECT * FROM temp_products'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end

      context 'for UPDATE statements' do
        [
          'UPDATE users SET name = "John" WHERE id = 1',
          'UPDATE products SET price = price * 1.1'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end

      context 'for DELETE statements' do
        [
          'DELETE FROM users WHERE id = 1',
          'DELETE FROM orders WHERE status = "cancelled"'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end

      context 'for other data modification statements' do
        [
          [ 'REPLACE INTO users (id, name) VALUES (1, "John")', /Query must begin with SELECT or WITH/ ],
          [ 'TRUNCATE TABLE users', /Query must begin with SELECT or WITH/ ]
        ].each do |query, error_pattern|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", error_pattern
          end
        end
      end
    end

    # Group 4: Invalid Queries - Schema Modifications
    context 'with schema modification queries' do
      context 'for CREATE statements' do
        [
          'CREATE TABLE new_table (id INT)',
          'CREATE INDEX idx_name ON users (name)',
          'CREATE VIEW user_view AS SELECT * FROM users',
          'CREATE TRIGGER trigger_name BEFORE INSERT ON users'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end

      context 'for DROP statements' do
        [
          'DROP TABLE users',
          'DROP INDEX idx_name',
          'DROP VIEW user_view',
          'DROP TRIGGER trigger_name'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end

      context 'for ALTER statements' do
        [
          'ALTER TABLE users ADD COLUMN email VARCHAR(255)',
          'ALTER TABLE users DROP COLUMN name',
          'ALTER TABLE users RENAME TO customers'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end

      context 'for RENAME statements' do
        let(:sql_query) { 'RENAME TABLE users TO customers' }
        it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
      end
    end

    # Group 5: Invalid Queries - Transaction Control
    context 'with transaction control queries' do
      [
        'COMMIT',
        'ROLLBACK',
        'SAVEPOINT sp1',
        'BEGIN TRANSACTION'
      ].each do |query|
        context "with query: #{query.inspect}" do
          let(:sql_query) { query }
          it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
        end
      end
    end

    # Group 6: Invalid Queries - Permission Control
    context 'with permission control queries' do
      context 'for GRANT statements' do
        let(:sql_query) { 'GRANT SELECT ON users TO user1' }
        it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
      end

      context 'for REVOKE statements' do
        let(:sql_query) { 'REVOKE SELECT ON users FROM user1' }
        it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
      end
    end

    # Group 7: Invalid Queries - Locking Statements
    context 'with locking statements' do
      [
        'LOCK TABLES users READ',
        'UNLOCK TABLES'
      ].each do |query|
        context "with query: #{query.inspect}" do
          let(:sql_query) { query }
          it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
        end
      end
    end

    # Group 8: Invalid Queries - Procedure/Function Execution
    context 'with procedure/function execution' do
      context 'for CALL statements' do
        let(:sql_query) { 'CALL stored_procedure()' }
        it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
      end

      context 'for EXECUTE statements' do
        [
          'EXECUTE procedure_name',
          'EXEC procedure_name'
        ].each do |query|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", /Query must begin with SELECT or WITH/
          end
        end
      end
    end

    # Group 9: SQL Injection Detection
    context 'with SQL injection attempts' do
      context 'for basic SQL injection' do
        [
          [ "SELECT * FROM users WHERE id = 1 OR 1=1", /SQL injection attempts/ ],
          [ "SELECT * FROM users WHERE name = 'admin' OR '1'='1'", /SQL injection attempts/ ],
          [ "SELECT * FROM users WHERE id = 1; DROP TABLE users; --", /suspicious patterns|Forbidden keyword 'DROP'|Multiple SQL statements/ ]
        ].each do |query, error_pattern|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", error_pattern
          end
        end
      end

      context 'for comment-based injection' do
        [
          [ "SELECT * FROM users WHERE id = 1 -- AND password = 'secret'", /suspicious patterns/ ],
          [ "SELECT * FROM users /* WHERE id = 1 */ WHERE 1=1", /suspicious patterns/ ]
        ].each do |query, error_pattern|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", error_pattern
          end
        end
      end

      context 'for database fingerprinting' do
        [
          [ "SELECT @@version", /SQL injection attempts/ ],
          [ "SELECT version()", /SQL injection attempts/ ]
        ].each do |query, error_pattern|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", error_pattern
          end
        end
      end

      context 'for hex-encoded injections' do
        let(:long_hex) { "0x" + "41" * 20 }
        let(:sql_query) { "SELECT * FROM users WHERE data = '#{long_hex}'" }
        it_behaves_like "an unsafe SQL query", /suspicious patterns/
      end

      context 'for excessive quotes' do
        let(:many_quotes) { "'" * 25 }
        let(:sql_query) { "SELECT * FROM users WHERE data = '#{many_quotes}'" }
        it_behaves_like "an unsafe SQL query", /suspicious patterns/
      end

      context 'for string concatenation injection' do
        [
          [ "SELECT * FROM users WHERE name = 'admin' || ' extra'", /suspicious patterns/ ],
          [ "SELECT * FROM users WHERE name = CONCAT('admin', ' extra')", /suspicious patterns/ ]
        ].each do |query, error_pattern|
          context "with query: #{query.inspect}" do
            let(:sql_query) { query }
            it_behaves_like "an unsafe SQL query", error_pattern
          end
        end
      end

      # Special cases for UNION-based injections
      context 'for union-based injections' do
        # Legitimate UNION query
        it "allows legitimate UNION queries" do
          sql = "SELECT * FROM users WHERE id = 1 UNION SELECT id, name FROM users WHERE id = 2"
          expect(described_class.safe_query?(sql)).to be true
        end

        # Malicious UNION query with special patterns
        it "rejects malicious UNION queries" do
          sql = "SELECT * FROM users WHERE id = 1 UNION SELECT user(), version(), @@hostname"
          expect(described_class.safe_query?(sql)).to be false
        end
      end

      context 'for privilege escalation attempts' do
        let(:sql_query) { "SELECT * FROM users WHERE id = 1 UNION SELECT LOAD_FILE('/etc/passwd')" }
        it_behaves_like "an unsafe SQL query", /SQL injection attempts/
      end
    end

    # Group 10: Multiple Statements and Edge Cases
    context 'with multiple statements' do
      [
        [ "SELECT * FROM users; SELECT * FROM products", /Multiple SQL statements/ ],
        [ "SELECT * FROM users; DROP TABLE products;", /Forbidden keyword 'DROP'|Multiple SQL statements/ ],
        [ "SELECT 1; INSERT INTO logs VALUES ('hack')", /Forbidden keyword 'INSERT'|Multiple SQL statements/ ]
      ].each do |query, error_pattern|
        context "with query: #{query.inspect}" do
          let(:sql_query) { query }
          it_behaves_like "an unsafe SQL query", error_pattern
        end
      end
    end

    context 'with case sensitivity' do
      {
        'select * from users' => true,
        'SELECT * FROM users' => true,
        'insert into users values (1)' => false,
        'INSERT INTO users VALUES (1)' => false,
        'Update users set name = "test"' => false,
        'DELETE from users' => false
      }.each do |query, expected|
        it "handles #{expected ? 'valid' : 'invalid'} query: #{query.inspect}" do
          expect(described_class.safe_query?(query)).to eq(expected)
        end
      end
    end

    context 'with whitespace and formatting variations' do
      [
        "  SELECT   *   FROM   users  ",
        "\nSELECT *\nFROM users\nWHERE id = 1\n",
        "\tSELECT\t*\tFROM\tusers"
      ].each do |query|
        context "with query: #{query.inspect}" do
          let(:sql_query) { query }
          it_behaves_like "a safe SQL query"
        end
      end

      it "handles multi-line formatted queries" do
        multiline_query = <<~SQL
          SELECT u.name,
                 p.title,
                 COUNT(*) as total
          FROM users u
          JOIN posts p ON u.id = p.user_id
          GROUP BY u.name, p.title
          ORDER BY total DESC
        SQL
        expect(described_class.safe_query?(multiline_query)).to be true
      end
    end

    # Group 11: Special Cases
    context 'with PRAGMA statements (SQLite specific)' do
      [
        'PRAGMA table_info(users)',
        'PRAGMA foreign_key_list(orders)',
        'PRAGMA index_list(users)'
      ].each do |query|
        context "with query: #{query.inspect}" do
          let(:sql_query) { query }

          it "rejects in safe_query?" do
            expect(described_class.safe_query?(sql_query)).to be false
          end

          it "allows in validate!" do
            expect { described_class.validate!(sql_query) }.not_to raise_error
          end
        end
      end
    end
  end

  describe '.validate!' do
    # Testing additional error cases for validate! specifically

    context 'with unsafe queries' do
      it 'raises SecurityError for data modification' do
        expect { described_class.validate!('INSERT INTO users VALUES (1)') }
          .to raise_error(SecurityError, /Query must begin with SELECT or WITH/)
      end

      it 'raises SecurityError for schema modification' do
        expect { described_class.validate!('DROP TABLE users') }
          .to raise_error(SecurityError, /Query must begin with SELECT or WITH/)
      end

      it 'raises SecurityError for blank queries' do
        expect { described_class.validate!('') }
          .to raise_error(SecurityError, 'Empty query is not allowed')

        expect { described_class.validate!(nil) }
          .to raise_error(SecurityError, 'Empty query is not allowed')
      end

      it 'raises SecurityError for overly long queries' do
        long_query = 'SELECT * FROM users WHERE name = ' + '"' + 'a' * 10000 + '"'
        expect { described_class.validate!(long_query) }
          .to raise_error(SecurityError, /Query exceeds maximum allowed length/)
      end

      it 'raises SecurityError for non-SELECT queries' do
        expect { described_class.validate!('FROM users') }
          .to raise_error(SecurityError, 'Query must begin with SELECT or WITH for security reasons')
      end

      it 'raises SecurityError for suspicious patterns' do
        expect { described_class.validate!('SELECT * FROM users -- malicious comment') }
          .to raise_error(SecurityError, /suspicious patterns/)
      end

      it 'raises SecurityError for multiple statements' do
        expect { described_class.validate!('SELECT * FROM users; DELETE FROM users') }
          .to raise_error(SecurityError, /Forbidden keyword 'DELETE' detected/)
      end
    end

    context 'with safe queries' do
      it 'returns normalized SQL for safe queries' do
        result = described_class.validate!('SELECT * FROM users WHERE id = 1')
        expect(result).to eq('SELECT * FROM users WHERE id = 1')

        # Test normalization
        result = described_class.validate!("  SELECT   *   FROM   users  ")
        expect(result).to eq('SELECT * FROM users')
      end

      it 'handles PRAGMA statements correctly' do
        expect(described_class.validate!('PRAGMA table_info(users)')).to eq('PRAGMA table_info(users)')
        expect(described_class.validate!('  PRAGMA   foreign_key_list(orders)  ')).to eq('PRAGMA foreign_key_list(orders)')
      end
    end
  end

  describe '.normalize' do
    it 'removes comments and normalizes whitespace' do
      sql = "SELECT * FROM users -- this is a comment"
      expect(described_class.normalize(sql)).to eq("SELECT * FROM users")

      sql = "SELECT * /* comment */ FROM users"
      expect(described_class.normalize(sql)).to eq("SELECT * FROM users")

      sql = "  SELECT   *   FROM   users  "
      expect(described_class.normalize(sql)).to eq("SELECT * FROM users")
    end

    it 'handles multiline comments' do
      sql = <<~SQL
        SELECT *
        /* this is a
           multiline comment */
        FROM users
      SQL
      expect(described_class.normalize(sql)).to eq("SELECT * FROM users")
    end

    it 'handles nil input' do
      expect(described_class.normalize(nil)).to eq("")
    end

    it 'handles malformed SQL gracefully' do
      # Mock Rails.logger to avoid actual logging during tests
      allow(Rails.logger).to receive(:error)

      # This should not raise an error, but return empty string
      result = described_class.normalize("SELECT * FROM users WHERE /* unclosed comment")
      expect(result).to be_a(String)
    end
  end

  describe 'configuration integration' do
    it 'respects max_query_length from configuration' do
      # Mock the configuration
      allow(Dbviewer).to receive(:configuration).and_return(
        double(max_query_length: 100)
      )

      long_query = 'SELECT * FROM users WHERE name = ' + '"' + 'a' * 100 + '"'
      expect(described_class.safe_query?(long_query)).to be false

      expect { described_class.validate!(long_query) }
        .to raise_error(SecurityError, /Query exceeds maximum allowed length \(100 chars\)/)
    end
  end

  describe 'real-world attack scenarios' do
    context 'with advanced injection techniques' do
      it 'handles blind SQL injection attempts' do
        # Time-based blind injection - benign example
        expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 AND (SELECT COUNT(*) FROM users) > 0")).to be true

        # Malicious time-based blind injection
        expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1; WAITFOR DELAY '00:00:05'")).to be false
      end

      it 'handles second-order injection attempts' do
        # Legitimate use of quotes
        expect(described_class.safe_query?("SELECT * FROM users WHERE name = 'O''Reilly'")).to be true

        # Malicious use of quotes
        expect(described_class.safe_query?("SELECT * FROM users WHERE name = ''' OR 1=1 --'")).to be false
      end

      it 'prevents privilege escalation attempts' do
        expect(described_class.safe_query?(
          "SELECT * FROM users WHERE id = 1 UNION SELECT user(), version(), @@hostname"
        )).to be false
      end

      it 'prevents file system access attempts' do
        expect(described_class.safe_query?(
          "SELECT * FROM users WHERE id = 1 UNION SELECT LOAD_FILE('/etc/passwd')"
        )).to be false
      end
    end

    context 'with information schema access' do
      context 'when enhanced protection is enabled' do
        before do
          configuration = instance_double(Dbviewer::Configuration, enhanced_sql_protection: true)
          allow(Dbviewer).to receive(:configuration).and_return(configuration)
        end

        it 'blocks potentially dangerous schema queries' do
          # Information schema access is blocked when enhanced protection is enabled
          expect(described_class.safe_query?("SELECT * FROM information_schema.tables")).to be false
          expect(described_class.safe_query?("SELECT * FROM mysql.user")).to be false
        end
      end

      context 'when enhanced protection is disabled' do
        before do
          configuration = instance_double(Dbviewer::Configuration, enhanced_sql_protection: false)
          allow(Dbviewer).to receive(:configuration).and_return(configuration)
        end

        it 'allows legitimate schema queries' do
          # These should be allowed when enhanced protection is disabled
          expect(described_class.safe_query?("SELECT * FROM information_schema.tables")).to be true
          expect(described_class.safe_query?("SELECT * FROM sqlite_master")).to be true
        end
      end

      it 'prevents schema modifications regardless of protection level' do
        # But we should prevent modifications
        expect(described_class.safe_query?("INSERT INTO information_schema.tables VALUES (...)")).to be false
      end
    end
  end
end
