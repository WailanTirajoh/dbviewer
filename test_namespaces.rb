#!/usr/bin/env ruby

# Test script to verify all namespaced classes load correctly

puts "Testing namespaced class loading..."

begin
  # Load basic modules first
  require './lib/dbviewer/version'
  require './lib/dbviewer/configuration'
  require './lib/dbviewer/sql_validator'
  puts "✓ Basic modules loaded"

  # Load storage modules
  require './lib/dbviewer/storage/base'
  require './lib/dbviewer/storage/in_memory_storage'
  require './lib/dbviewer/storage/file_storage'
  puts "✓ Storage modules loaded"

  # Load query modules
  require './lib/dbviewer/query/parser'
  require './lib/dbviewer/query/collection'
  require './lib/dbviewer/query/logger'
  require './lib/dbviewer/query/analyzer'
  require './lib/dbviewer/query/executor'
  puts "✓ Query modules loaded"

  # Load database modules
  require './lib/dbviewer/database/cache_manager'
  require './lib/dbviewer/database/dynamic_model_factory'
  require './lib/dbviewer/database/manager'
  puts "✓ Database modules loaded"

  # Load datatable modules
  require './lib/dbviewer/datatable/query_params'
  require './lib/dbviewer/datatable/metadata_manager'
  require './lib/dbviewer/datatable/query_operations'
  puts "✓ Datatable modules loaded"

  puts
  puts "All namespaced classes loaded successfully!"
  puts
  puts "Available namespaces and classes:"
  puts "================================="
  puts
  puts "Dbviewer::Query::"
  puts "  ├── Executor"
  puts "  ├── Analyzer"
  puts "  ├── Collection"
  puts "  ├── Logger"
  puts "  └── Parser"
  puts
  puts "Dbviewer::Database::"
  puts "  ├── CacheManager"
  puts "  ├── DynamicModelFactory"
  puts "  └── Manager"
  puts
  puts "Dbviewer::Datatable::"
  puts "  ├── MetadataManager"
  puts "  ├── QueryOperations"
  puts "  └── QueryParams"
  puts
  puts "Dbviewer::Storage::"
  puts "  ├── Base"
  puts "  ├── InMemoryStorage"
  puts "  └── FileStorage"
  puts
  puts "Root level classes:"
  puts "  ├── Configuration"
  puts "  ├── SqlValidator"
  puts "  └── VERSION (#{Dbviewer::VERSION})"

rescue => e
  puts "✗ Error loading classes: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end
