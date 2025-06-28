# DBViewer Security Guide

## Overview

DBViewer includes comprehensive security measures to protect against SQL injection and other database security vulnerabilities. This document outlines the security features, best practices, and configuration options available.

## SQL Injection Protection

### Multi-Layer Validation System

DBViewer employs a multi-layer validation system to prevent SQL injection attacks:

1. **Input Sanitization**: Raw input is sanitized to remove null bytes and limit query length
2. **Threat Detection**: Advanced pattern matching identifies injection attempts
3. **Query Validation**: Only SELECT and WITH statements are allowed
4. **Keyword Filtering**: Forbidden keywords (INSERT, DELETE, UPDATE, DROP, etc.) are blocked
5. **Security Logging**: All security events are logged for monitoring

### Supported Attack Prevention

The system detects and prevents:
- Basic SQL injection (`OR 1=1`, `OR '1'='1'`)
- Time-based blind injection (`WAITFOR DELAY`, `SLEEP`, `BENCHMARK`)
- Error-based injection (`CONVERT`, `EXTRACTVALUE`)
- Information disclosure (`@@version`, `version()`, `information_schema`)
- File access attempts (`LOAD_FILE`, `INTO OUTFILE`)
- Stacked queries (multiple statements separated by semicolons)
- Comment injection (`--`, `/* */`)
- String concatenation attacks (`||`, `CONCAT`)
- Hex-encoded payloads
- Script and code injection attempts

## Configuration Options

### Security Settings

```ruby
Dbviewer.configure do |config|
  # Enable comprehensive security logging
  config.log_queries = true
  config.log_security_events = true
  
  # Enhanced SQL injection protection
  config.enhanced_sql_protection = true
  
  # Query limits
  config.max_query_length = 10000
  config.max_records = 10000
  
  # Security event storage
  config.max_security_events = 1000
end
```

### Access Control

```ruby
Dbviewer.configure do |config|
  # Whitelist approach (most secure)
  config.access_control_mode = :whitelist
  config.allowed_tables = ['users', 'orders', 'products']
  
  # Or blacklist approach
  config.access_control_mode = :blacklist
  config.blocked_tables = ['admin_users', 'sensitive_data']
  
  # Hide sensitive columns
  config.blocked_columns = {
    'users' => ['password_digest', 'api_key'],
    'orders' => ['internal_notes']
  }
end
```

## Security Logging

### Query Monitoring

All database operations are logged with the following information:
- SQL query text (truncated for security)
- Query type (query, pragma, etc.)
- Timestamp
- Request ID and thread ID for tracing

### Security Event Logging

Security threats are logged with detailed information:
- Event type (threat_detected, unsafe_query_blocked, etc.)
- Threat category (injection_patterns, suspicious_patterns, etc.)
- Original SQL query
- Timestamp and context

### Log Location

Security events are logged to:
- Rails application log with `[DBViewer][Security]` prefix
- In-memory storage for analysis (configurable limit)
- Optional file-based logging (when configured)

## Best Practices

### For Application Administrators

1. **Enable Security Logging**: Always enable comprehensive logging in production
2. **Monitor Security Events**: Regularly review security logs for attack attempts
3. **Use Whitelisting**: When possible, use whitelist access control for maximum security
4. **Limit Query Length**: Set appropriate maximum query length limits
5. **Regular Security Reviews**: Periodically review blocked queries and adjust patterns

### For Developers

1. **Input Validation**: Always validate and sanitize user input before processing
2. **Parameterized Queries**: Use parameterized queries when building dynamic SQL
3. **Least Privilege**: Ensure database connections use minimal necessary permissions
4. **Error Handling**: Don't expose detailed error messages to end users
5. **Regular Updates**: Keep DBViewer updated to get the latest security enhancements

### For Database Administrators

1. **Database User Permissions**: Create dedicated read-only database users for DBViewer
2. **Network Security**: Restrict database access to authorized networks
3. **Connection Encryption**: Use SSL/TLS for database connections
4. **Query Monitoring**: Monitor database query logs for suspicious activity
5. **Regular Backups**: Maintain regular database backups as a security measure

## Security Features Implementation

### Query Validation Process

1. **Basic Validation**: Check for null/empty queries and length limits
2. **Threat Detection**: Scan for injection patterns and suspicious content
3. **Normalization**: Clean and normalize the SQL query
4. **Structure Validation**: Ensure query starts with allowed statements
5. **Keyword Filtering**: Block forbidden SQL keywords
6. **Multiple Statement Detection**: Prevent stacked queries

### Error Handling

- Unsafe queries are automatically replaced with safe default queries
- Users receive informative warnings without exposing security details
- All security violations are logged for analysis
- Application continues to function even when attacks are blocked

## Troubleshooting

### Common Issues

**Q: My legitimate query is being blocked**
A: Check the security logs to see which pattern triggered the block. You may need to adjust the query syntax or contact an administrator.

**Q: How do I view security logs?**
A: Security events are logged to your Rails application log with the `[DBViewer][Security]` prefix.

**Q: Can I disable security features?**
A: While possible, it's strongly discouraged. Instead, adjust the configuration to meet your specific needs.

### Debugging Security Issues

1. Check Rails logs for `[DBViewer][Security]` entries
2. Review the specific threat pattern that was triggered
3. Verify your query syntax matches allowed patterns
4. Test with simpler queries to isolate the issue

## Regular Security Maintenance

### Weekly Tasks
- Review security event logs
- Check for new attack patterns
- Monitor query performance impact

### Monthly Tasks
- Update security configurations
- Review access control settings
- Analyze security metrics

### Quarterly Tasks
- Security audit of configurations
- Update DBViewer to latest version
- Review and update documentation

## Contact and Support

For security-related questions or to report vulnerabilities, please:
1. Review this documentation thoroughly
2. Check the security logs for specific error messages
3. Contact your system administrator
4. Report security issues through appropriate channels

Remember: Security is a shared responsibility between the application, database, and infrastructure layers.