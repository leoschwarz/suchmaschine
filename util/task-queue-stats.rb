#!/usr/bin/env ruby
# Gibt Auskunft über die TaskQueue

logfile_path = File.join(File.dirname(__FILE__), "../db/task_queue.log")

total_lines = 0
domain_counts = {}

logfile = File.open(logfile_path, "r")
logfile.each_line do |line|
  total_lines += 1
  x,url,c = line.split("\t")
  match = /https?:\/\/([a-zA-Z0-9\.-]+)/.match(url)
  if not match.nil?
    domain_name = match[1].downcase
    if domain_counts.has_key? domain_name
      domain_counts[domain_name] += c.to_i + 1
    else
      domain_counts[domain_name]  = c.to_i + 1
    end
  end
end

puts "Total Zeilen: #{total_lines}"
puts "Top 50 Domains:"
puts domain_counts.sort_by{|url, c| c}.reverse[0..50].map{|row| row.join(" => ")}