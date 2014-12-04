require_relative "model"

filename = "test.sqlite3"

ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: filename)
