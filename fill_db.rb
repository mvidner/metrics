#! /usr/bin/env ruby
require "sqlite3"
require "fileutils"

# Usage fill_db REPO_DIR URL METRIC_NAME DATE_FROM DATE_TO
repo_dir, url, metric_name, date_from, date_to = ARGV
prefer_old_values = ENV["OLD"]

# ./fill_db.rb ~/svn/yast-bootloader/ git@github.com:yast/yast-bootloader.git loc-1 2014-01-31 `date -I`

CANONICAL_BASE = "git://github.com/".freeze
# convert one of these
#   git@github.com:yast/yast-bootloader.git
#   git://github.com/yast/yast-bootloader.git
#   https://github.com/yast/yast-bootloader.git
# to
#   git://github.com/yast/yast-bootloader.git
def canonical_git_url(s)
  s.
    sub("git@github.com:",     CANONICAL_BASE).
    sub("https://github.com/", CANONICAL_BASE)
end

url = canonical_git_url(url)
metric_program = File.expand_path("../bin/#{metric_name}", __FILE__)
date_from = Date.parse date_from
date_to   = Date.parse date_to

def may_add_repo
  true
end

$db = SQLite3::Database.new "metrics.sqlite"

def find_repo_by_url(url)
  p url
  $db.execute("SELECT * FROM repos WHERE url = ?;", url).first
end

def add_repo(url)
  $db.execute("INSERT INTO repos (url) VALUES (?);", url)
end

def repo_id_by_url(url)
  row = find_repo_by_url(url)
  if row.nil?
    if may_add_repo
      add_repo(url)
      row = find_repo_by_url(url)
    else
      fail "Cannot find repo URL #{url} in DB"
    end
  end
  row.first
end

repo_id = repo_id_by_url(url)

def find_metric_by_name(name)
  $db.execute("SELECT * FROM metric_names WHERE name = ?;", name).first
end

def metric_id_by_name(name)
  row = find_metric_by_name(name)
  row ? row.first : nil
end

metric_id = metric_id_by_name(metric_name)
if metric_id.nil?
  fail "Cannot find metric '#{metric_name}' in DB"
end

def find_metric_value(date, repo_id, metric_name_id)
  sql = "SELECT * FROM metric_values " \
        "WHERE date = ? AND repo_id = ? AND metric_name_id = ?;"
  $db.execute(sql, [date.to_s, repo_id, metric_name_id]).first
end

def dates_between(from, to, &block)
  raise ArgumentError("starting date is after ending date") if from > to
  loop do
    block.call(from)
    break if from == to
    from = from.next_day
  end
end

def metric(program, date)
  `git checkout --quiet $(git rev-list -n1 --until #{date} master); #{program}`.chomp.to_f
end

dates_between(date_from, date_to) do |date|
  value = nil
  FileUtils.cd(repo_dir) do
    value = metric(metric_program, date)
  end

  puts "#{date}: #{value}"

  found = find_metric_value(date, repo_id, metric_id)
  if found
    old_value = found.last
    if old_value != value
      message = "Metric value already present: #{found.inspect}"
      if prefer_old_values
        puts message
      else
        raise message
      end
    end
  else
    sql = "INSERT INTO metric_values (date, repo_id, metric_name_id, value) VALUES (?, ?, ?, ?);"
    $db.execute(sql, [date.to_s, repo_id, metric_id, value])
  end
end

system "cd #{repo_dir}; git checkout --quiet master"
