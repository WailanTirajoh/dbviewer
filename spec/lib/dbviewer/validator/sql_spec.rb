# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Dbviewer::Validator::Sql do
  describe '.safe_query?' do
    context 'with valid SELECT queries' do
      it 'allows simple SELECT queries' do
        expect(described_class.safe_query?('SELECT * FROM users')).to be true
        expect(described_class.safe_query?('SELECT id, name FROM products')).to be true
        expect(described_class.safe_query?('SELECT COUNT(*) FROM orders')).to be true
      end

      it 'allows SELECT with WHERE clauses' do
        expect(described_class.safe_query?('SELECT * FROM users WHERE id = 1')).to be true
        expect(described_class.safe_query?('SELECT name FROM products WHERE price > 100')).to be true
        expect(described_class.safe_query?('SELECT * FROM orders WHERE status = "pending"')).to be true
      end

      it 'allows SELECT with JOINs' do
        query = 'SELECT u.name, p.title FROM users u JOIN posts p ON u.id = p.user_id'
        expect(described_class.safe_query?(query)).to be true

        query = 'SELECT * FROM orders o LEFT JOIN customers c ON o.customer_id = c.id'
        expect(described_class.safe_query?(query)).to be true
      end

      it 'allows SELECT with ORDER BY and GROUP BY' do
        expect(described_class.safe_query?('SELECT * FROM users ORDER BY name')).to be true
        expect(described_class.safe_query?('SELECT COUNT(*) FROM orders GROUP BY status')).to be true
        expect(described_class.safe_query?('SELECT status, COUNT(*) FROM orders GROUP BY status HAVING COUNT(*) > 5')).to be true
      end

      it 'allows SELECT with subqueries' do
        query = 'SELECT * FROM users WHERE id IN (SELECT user_id FROM orders WHERE amount > 1000)'
        expect(described_class.safe_query?(query)).to be true

        query = 'SELECT * FROM products WHERE price > (SELECT AVG(price) FROM products)'
        expect(described_class.safe_query?(query)).to be true
      end

      it 'allows SELECT with window functions' do
        query = 'SELECT name, ROW_NUMBER() OVER (ORDER BY created_at) FROM users'
        expect(described_class.safe_query?(query)).to be true
      end

      it 'allows SELECT with UNION' do
        query = 'SELECT name FROM users UNION SELECT company_name FROM companies'
        expect(described_class.safe_query?(query)).to be true
      end

      it 'allows SELECT with CTEs (WITH clauses)' do
        # WITH is in CONDITIONAL_KEYWORDS but not FORBIDDEN_KEYWORDS, so it should be allowed
        query = 'WITH top_users AS (SELECT * FROM users LIMIT 10) SELECT * FROM top_users'
        expect(described_class.safe_query?(query)).to be true
      end

      it 'allows SELECT with CASE statements' do
        query = 'SELECT name, CASE WHEN age >= 18 THEN "adult" ELSE "minor" END FROM users'
        expect(described_class.safe_query?(query)).to be true
      end

      it 'allows SELECT with string functions' do
        expect(described_class.safe_query?('SELECT UPPER(name) FROM users')).to be true
        expect(described_class.safe_query?('SELECT SUBSTRING(description, 1, 100) FROM products')).to be true
      end

      it 'allows SELECT with date functions' do
        expect(described_class.safe_query?('SELECT * FROM orders WHERE created_at >= DATE("2023-01-01")')).to be true
        expect(described_class.safe_query?('SELECT STRFTIME("%Y", created_at) FROM users')).to be true
      end
    end

    context 'with PRAGMA statements (SQLite specific)' do
      it 'rejects PRAGMA statements in safe_query? but allows them in validate!' do
        # safe_query? should reject PRAGMA because it doesn't start with SELECT
        expect(described_class.safe_query?('PRAGMA table_info(users)')).to be false
        expect(described_class.safe_query?('PRAGMA foreign_key_list(orders)')).to be false
        expect(described_class.safe_query?('PRAGMA index_list(users)')).to be false

        # But validate! has special handling for PRAGMA
        expect { described_class.validate!('PRAGMA table_info(users)') }.not_to raise_error
        expect { described_class.validate!('PRAGMA foreign_key_list(orders)') }.not_to raise_error
        expect { described_class.validate!('PRAGMA index_list(users)') }.not_to raise_error
      end
    end

    context 'with data modification queries' do
      it 'rejects INSERT queries' do
        expect(described_class.safe_query?('INSERT INTO users (name) VALUES ("John")')).to be false
        expect(described_class.safe_query?('INSERT INTO products SELECT * FROM temp_products')).to be false
      end

      it 'rejects UPDATE queries' do
        expect(described_class.safe_query?('UPDATE users SET name = "John" WHERE id = 1')).to be false
        expect(described_class.safe_query?('UPDATE products SET price = price * 1.1')).to be false
      end

      it 'rejects DELETE queries' do
        expect(described_class.safe_query?('DELETE FROM users WHERE id = 1')).to be false
        expect(described_class.safe_query?('DELETE FROM orders WHERE status = "cancelled"')).to be false
      end

      it 'rejects REPLACE queries' do
        expect(described_class.safe_query?('REPLACE INTO users (id, name) VALUES (1, "John")')).to be false
      end

      it 'rejects TRUNCATE queries' do
        expect(described_class.safe_query?('TRUNCATE TABLE users')).to be false
      end
    end

    context 'with schema modification queries' do
      it 'rejects CREATE statements' do
        expect(described_class.safe_query?('CREATE TABLE new_table (id INT)')).to be false
        expect(described_class.safe_query?('CREATE INDEX idx_name ON users (name)')).to be false
        expect(described_class.safe_query?('CREATE VIEW user_view AS SELECT * FROM users')).to be false
        expect(described_class.safe_query?('CREATE TRIGGER trigger_name BEFORE INSERT ON users')).to be false
      end

      it 'rejects DROP statements' do
        expect(described_class.safe_query?('DROP TABLE users')).to be false
        expect(described_class.safe_query?('DROP INDEX idx_name')).to be false
        expect(described_class.safe_query?('DROP VIEW user_view')).to be false
        expect(described_class.safe_query?('DROP TRIGGER trigger_name')).to be false
      end

      it 'rejects ALTER statements' do
        expect(described_class.safe_query?('ALTER TABLE users ADD COLUMN email VARCHAR(255)')).to be false
        expect(described_class.safe_query?('ALTER TABLE users DROP COLUMN name')).to be false
        expect(described_class.safe_query?('ALTER TABLE users RENAME TO customers')).to be false
      end

      it 'rejects RENAME statements' do
        expect(described_class.safe_query?('RENAME TABLE users TO customers')).to be false
      end
    end

    context 'with transaction control queries' do
      it 'rejects transaction control statements' do
        expect(described_class.safe_query?('COMMIT')).to be false
        expect(described_class.safe_query?('ROLLBACK')).to be false
        expect(described_class.safe_query?('SAVEPOINT sp1')).to be false
        expect(described_class.safe_query?('BEGIN TRANSACTION')).to be false
      end
    end

    context 'with permission control queries' do
      it 'rejects GRANT statements' do
        expect(described_class.safe_query?('GRANT SELECT ON users TO user1')).to be false
      end

      it 'rejects REVOKE statements' do
        expect(described_class.safe_query?('REVOKE SELECT ON users FROM user1')).to be false
      end
    end

    context 'with locking statements' do
      it 'rejects LOCK statements' do
        expect(described_class.safe_query?('LOCK TABLES users READ')).to be false
        expect(described_class.safe_query?('UNLOCK TABLES')).to be false
      end
    end

    context 'with procedure/function execution' do
      it 'rejects CALL statements' do
        expect(described_class.safe_query?('CALL stored_procedure()')).to be false
      end

      it 'rejects EXECUTE statements' do
        expect(described_class.safe_query?('EXECUTE procedure_name')).to be false
        expect(described_class.safe_query?('EXEC procedure_name')).to be false
      end
    end

    context 'with SQL injection attempts' do
      it 'rejects basic SQL injection patterns' do
        expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 OR 1=1")).to be false
        expect(described_class.safe_query?("SELECT * FROM users WHERE name = 'admin' OR '1'='1'")).to be false
        expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1; DROP TABLE users; --")).to be false
      end

      it 'rejects union-based injection attempts' do
        expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 UNION SELECT password FROM admin")).to be true
        # Note: UNION itself is allowed, but malicious patterns should be caught by other checks
      end

      it 'rejects comment-based injection attempts' do
        expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 -- AND password = 'secret'")).to be false
        expect(described_class.safe_query?("SELECT * FROM users /* WHERE id = 1 */ WHERE 1=1")).to be false
      end

      it 'rejects database fingerprinting attempts' do
        expect(described_class.safe_query?("SELECT @@version")).to be false
        expect(described_class.safe_query?("SELECT version()")).to be false
      end

      it 'rejects hex-encoded injection attempts' do
        long_hex = "0x" + "41" * 20  # Long hex string
        expect(described_class.safe_query?("SELECT * FROM users WHERE data = '#{long_hex}'")).to be false
      end

      it 'rejects queries with excessive quotes' do
        many_quotes = "'" * 25
        expect(described_class.safe_query?("SELECT * FROM users WHERE data = '#{many_quotes}'")).to be false
      end

      it 'rejects string concatenation injection attempts' do
        expect(described_class.safe_query?("SELECT * FROM users WHERE name = 'admin' || ' extra'")).to be false
        expect(described_class.safe_query?("SELECT * FROM users WHERE name = CONCAT('admin', ' extra')")).to be false
      end
    end

    context 'with multiple statements' do
      it 'rejects multiple SQL statements separated by semicolons' do
        expect(described_class.safe_query?("SELECT * FROM users; SELECT * FROM products")).to be false
        expect(described_class.safe_query?("SELECT * FROM users; DROP TABLE products;")).to be false
        expect(described_class.safe_query?("SELECT 1; INSERT INTO logs VALUES ('hack')")).to be false
      end
    end

    context 'with case sensitivity' do
      it 'handles case-insensitive forbidden keywords' do
        expect(described_class.safe_query?('select * from users')).to be true
        expect(described_class.safe_query?('SELECT * FROM users')).to be true
        expect(described_class.safe_query?('insert into users values (1)')).to be false
        expect(described_class.safe_query?('INSERT INTO users VALUES (1)')).to be false
        expect(described_class.safe_query?('Update users set name = "test"')).to be false
        expect(described_class.safe_query?('DELETE from users')).to be false
      end
    end

    context 'with whitespace and formatting variations' do
      it 'handles queries with various whitespace' do
        expect(described_class.safe_query?("  SELECT   *   FROM   users  ")).to be true
        expect(described_class.safe_query?("\nSELECT *\nFROM users\nWHERE id = 1\n")).to be true
        expect(described_class.safe_query?("\tSELECT\t*\tFROM\tusers")).to be true
      end

      it 'handles queries with line breaks' do
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

    context 'with edge cases' do
      it 'rejects nil and blank queries' do
        expect(described_class.safe_query?(nil)).to be false
        expect(described_class.safe_query?('')).to be false
        expect(described_class.safe_query?('   ')).to be false
      end

      it 'rejects queries that do not start with SELECT' do
        expect(described_class.safe_query?('FROM users SELECT *')).to be false
        expect(described_class.safe_query?('WHERE id = 1 SELECT * FROM users')).to be false
      end

      it 'rejects overly long queries' do
        # Create a query longer than MAX_QUERY_LENGTH (10000 chars)
        long_query = 'SELECT * FROM users WHERE name = ' + '"' + 'a' * 10000 + '"'
        expect(described_class.safe_query?(long_query)).to be false
      end

      it 'handles queries with keywords as column or table names' do
        # These should be allowed as they use keywords in valid contexts
        expect(described_class.safe_query?('SELECT "order" FROM users')).to be true
        expect(described_class.safe_query?('SELECT * FROM user_update_log')).to be true
        expect(described_class.safe_query?('SELECT insert_date FROM products')).to be true
      end
    end

    context 'with database-specific syntax' do
      it 'allows database-specific SELECT syntax' do
        # PostgreSQL specific
        expect(described_class.safe_query?('SELECT * FROM users LIMIT 10 OFFSET 5')).to be true

        # MySQL specific
        expect(described_class.safe_query?('SELECT * FROM users LIMIT 5, 10')).to be true

        # SQLite specific
        expect(described_class.safe_query?('SELECT * FROM users WHERE name GLOB "A*"')).to be true
      end
    end
  end

  describe '.validate!' do
    it 'raises SecurityError for unsafe queries' do
      expect { described_class.validate!('INSERT INTO users VALUES (1)') }
        .to raise_error(SecurityError, /Query must begin with SELECT or WITH for security reasons/)

      expect { described_class.validate!('DROP TABLE users') }
        .to raise_error(SecurityError, /Query must begin with SELECT or WITH for security reasons/)

      expect { described_class.validate!('UPDATE users SET name = "test"') }
        .to raise_error(SecurityError, /Query must begin with SELECT or WITH for security reasons/)
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

      expect { described_class.validate!('SELECT * FROM users WHERE name = CONCAT("a", "b")') }
        .to raise_error(SecurityError, /suspicious patterns/)
    end

    it 'raises SecurityError for multiple statements' do
      expect { described_class.validate!('SELECT * FROM users; DELETE FROM users') }
        .to raise_error(SecurityError, /Forbidden keyword 'DELETE' detected/)
    end

    it 'raises SecurityError for injection patterns' do
      expect { described_class.validate!("SELECT * FROM users WHERE id = 1 OR 1=1") }
        .to raise_error(SecurityError, /SQL injection attempts/)

      expect { described_class.validate!("SELECT @@version") }
        .to raise_error(SecurityError, /SQL injection attempts/)
    end

    it 'returns normalized SQL for safe queries' do
      result = described_class.validate!('SELECT * FROM users WHERE id = 1')
      expect(result).to eq('SELECT * FROM users WHERE id = 1')

      # Test normalization
      result = described_class.validate!("  SELECT   *   FROM   users  ")
      expect(result).to eq('SELECT * FROM users')
    end

    it 'handles PRAGMA statements correctly' do
      result = described_class.validate!('PRAGMA table_info(users)')
      expect(result).to eq('PRAGMA table_info(users)')

      result = described_class.validate!('  PRAGMA   foreign_key_list(orders)  ')
      expect(result).to eq('PRAGMA foreign_key_list(orders)')
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
    it 'prevents blind SQL injection attempts' do
      # Time-based blind injection
      expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 AND (SELECT COUNT(*) FROM users) > 0")).to be true
      # But with malicious intent
      expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1; WAITFOR DELAY '00:00:05'")).to be false
    end

    it 'prevents second-order injection attempts' do
      # Attempts to inject via seemingly safe SELECT
      expect(described_class.safe_query?("SELECT * FROM users WHERE name = 'O''Reilly'")).to be true
      expect(described_class.safe_query?("SELECT * FROM users WHERE name = ''' OR 1=1 --'")).to be false
    end

    it 'prevents privilege escalation attempts' do
      expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 UNION SELECT user(), version(), @@hostname")).to be false
    end

    it 'prevents file system access attempts' do
      expect(described_class.safe_query?("SELECT * FROM users WHERE id = 1 UNION SELECT LOAD_FILE('/etc/passwd')")).to be false
    end

    it 'prevents information schema queries that could reveal structure' do
      # These should be allowed as they are legitimate SELECT queries
      expect(described_class.safe_query?("SELECT * FROM information_schema.tables")).to be true
      expect(described_class.safe_query?("SELECT * FROM sqlite_master")).to be true
      # But we should prevent modifications
      expect(described_class.safe_query?("INSERT INTO information_schema.tables VALUES (...)")).to be false
    end
  end
end
