#! /usr/bin/env ruby
require "sqlite3"

db = SQLite3::Database.new "metrics.sqlite"

data = File.open("metrics.dat") do |f|
  f.each_line do |l|
    date, value = l.split
    db.execute(<<-SQL, [date, 1, 1, value.to_i])
      INSERT INTO metric_values (date, repo_id, metric_name_id, value)
             VALUES (?, ?, ?, ?);
      SQL
  end
end
