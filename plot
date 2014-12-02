#! /usr/bin/env ruby
require "open3"
require "sqlite3"

def send_data(io, repo_id, metric_name_id)
  db = SQLite3::Database.new "metrics.sqlite"
  sql = "SELECT date, value FROM metric_values " \
    "WHERE repo_id = ? AND metric_name_id = ?"
  db.execute(sql, [repo_id, metric_name_id]) do |date, value|
    io.puts "#{date} #{value}"
  end
  io.puts "e"
end

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
GNUPLOT

  g_stdin.puts 'plot "-" using 1:2 with points title "loc-1 yast-network"'
  send_data(g_stdin, 1, 1)

#  g_stdin.puts 'plot "-" using 1:2 with points title "loc-1 yast-bootloader"'
#  send_data(g_stdin, 2, 1)

#  g_stdin.close
end
