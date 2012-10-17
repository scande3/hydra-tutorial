#! /usr/bin/env ruby

require 'set'
require 'fileutils'

tasks = %w(
  zzz
  aaa
  bbb
  ccc
)

done_file = 'done.txt'
FileUtils.touch(done_file) unless File.file?(done_file)

if ARGV.delete('--reset')
  File.open(done_file, "w") {  }
  exit
end

if ARGV.size > 0
  task = ARGV.shift
else
  done = Set.new(File.read(done_file).split("\n"))
  tasks.each do |t|
    next if done.include?(t)
    File.open(done_file, "a") { |f| f.puts(t) }
    task = t
    break
  end
end

if task
  puts "thor app:#{task} #{ARGV.join ' '}"
else
  puts "all tasks have been completed"
end
