require 'nokogiri'
require 'net/http'

require './lib/database.rb'
require './lib/robots.rb'
require './lib/url_parser.rb'
require './lib/html_parser.rb'
require './lib/download.rb'

ROBOT_NAME = "lightblaze"
$robots = RobotsParser.new(ROBOT_NAME)

if __FILE__ == $0
  loop do
    tasks = Task.sample(100)
    tasks.each do |task|
      if task.allowed?
        download = Download.new(task)
        begin
          download.run
          puts "[+] #{task.decoded_url[0...64]}  (#{download.time.round 2}s)"
        rescue Exception => e
          raise e
          puts "[-] #{task.decoded_url[0...64]}"
          puts e.message
        end
      end
    end
    puts "[*] Finished sample."
  end
end
