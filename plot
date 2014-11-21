#! /usr/bin/env ruby
require "open3"
require "sqlite3"

Open3.pipeline_rw("gnuplot") do |g_stdin, g_stdout, g_wait_thrs|
  g_stdin.print <<'GNUPLOT'
set terminal png
set output "plot.png"

set title "Lines of Code (*.rb) over time"

# labels for the x axis
set format x "%Y\n%m"

# input
set xdata time
set timefmt x "%Y-%m-%d"
set xrange ["2013-11-22":"2014-11-21"]

plot "-" using 1:2 with lines title "yast-network"
GNUPLOT

  db = SQLite3::Database.new "metrics.sqlite"
  Q = "SELECT date, value FROM metric_values WHERE repo_id = ? AND metric_name_id = ?"
  db.execute(Q, [1, 1]) do |date, value|
    g_stdin.puts "#{date} #{value}"
  end
  g_stdin.puts "e"
#  g_stdin.close
end
