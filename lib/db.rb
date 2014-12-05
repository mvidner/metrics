require_relative "model"

filename = "metrics.sqlite3"

ActiveRecord::Base.establish_connection(
  adapter:  'sqlite3',
  database: filename,
  timeout:  5000                # ms
)
