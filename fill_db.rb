#! /usr/bin/env ruby
require "sqlite3"
require "fileutils"

# Usage fill_db DB URL METRIC_NAME DATE_FROM DATE_TO
repo_dir, url, metric_name, date_from, date_to = ARGV

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

may_add_repo = true


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

if metric_name == "loc-1"
  metric_id = 1
else
  fail "Not implemented"
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
  `git checkout --quiet $(git rev-list -n1 --until #{date} master); #{program}`.chomp
end

dates_between(date_from, date_to) do |date|
  value = nil
  FileUtils.cd(repo_dir) do
    value = metric(metric_program, date)
  end

  sql = "INSERT INTO metric_values (date, repo_id, metric_name_id, value) VALUES (?, ?, ?, ?);"
  #$db.execute(sql, [date.to_s, repo_id, metric_id, value])
  puts "#{date}: #{value}"
end

system "cd #{repo_dir}; git checkout --quiet master"
