############################################################################################
# Diese Datei lädt das Modul «Common»                                                      #
############################################################################################

# Die Fehler in Threads sollen gefangen werden müssen, anstatt einfach stumm unterzugehen.
Thread.abort_on_exception = true

# Das Modul laden.
require_relative './config.rb'
require_relative './index_file.rb'
require_relative './logger.rb'
require_relative './progress_logger.rb'
require_relative './ram_cache.rb'
require_relative './serializable.rb'
require_relative './url.rb'
require_relative './worker_threads.rb'
require_relative './database/database.rb'
