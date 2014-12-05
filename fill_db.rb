#! /usr/bin/env ruby
require "fileutils"
require_relative "lib/db"

if ARGV.first == "-a"
  may_add = true
  ARGV.shift
end

if ARGV.first == "-r"
  replace = true
  ARGV.shift
end

# Usage fill_db REPO_DIR URL METRIC_NAME DATE_FROM DATE_TO
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

def dates_between(from, to, &block)
  raise ArgumentError("starting date is after ending date") if from > to
  loop do
    block.call(from)
    break if from == to
    from = from.next_day
  end
end

def measure(program, date)
  rev = `git rev-list -n1 --first-parent --until #{date} master`.chomp
  `git checkout --quiet #{rev}; #{program}`.chomp.to_f
end

repo = Repo.find_by_url(url)
if !repo && may_add
  repo = Repo.create!(url: url)
end

metric = Metric.find_by_name(metric_name)
if !metric && may_add
  metric = Metric.create!(name: metric_name)
end

dates_between(date_from, date_to) do |date|
  value = nil
  FileUtils.cd(repo_dir) do
    value = measure(metric_program, date)
  end

  puts "#{date}: #{value}"

  key = { date: date, repo: repo, metric: metric }
  measurement = Measurement.find_by(key)
  if !measurement
    Measurement.create!(key.merge(value: value))
  else
    old_value = measurement.value
    if old_value != value
      print " Old value: #{old_value} "
      if replace
        puts "Replaced"
        measurement.value = value
        measurement.save
      else
        fail
      end
    end
  end
end

system "cd #{repo_dir}; git checkout --quiet master"
