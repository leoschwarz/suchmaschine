module Crawler
  class Client
    def launch
      labels  = {success: :Erfolge, failure: :Fehler, not_allowed: :Verboten}
      @logger = Common::Logger.new({labels: labels})
      @logger.add_output($stdout, Common::Logger::INFO)
      @progress = @logger.progress_logger({success: 0, failure: 0, not_allowed: 0})
      
      @logger.log_info("Crawler-Client wurde gestartet.")
      @logger.log_info("Threads: #{Config.crawler.threads}")
      @logger.log_info("Server:  #{Config.database_connection}")
      
      Common::WorkerThreads.run(Config.crawler.threads, blocking: false) do
        loop do
          begin
            result_type = Crawler::Task.fetch.execute
            @progress[result_type] += 1
          rescue => e
            @logger.log_exception(e)
          end
        end
      end
            
      @progress.start_display(5.0)
      sleep
    end
  end
end
