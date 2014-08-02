module Crawler
  # Anzahl Aufgaben die in der Memory-Warteschleife enthalten sein sollen
  TASK_QUEUE_SIZE = 100
  # Anzahl paralleler Downloads
  PARALLEL_TASKS  = 10
  # Benutzeragent der bei Requests mitgesendet wird, und nach dem in robots.txt Dateien gesucht wird.
  USER_AGENT = "lightblaze"
  # Timeout von robots.txt requests in Sekunden
  ROBOTS_TXT_TIMEOUT = 10
  # Maximales Alter von gecachten robots.txt Regeln in Sekunden
  ROBOTS_TXT_CACHE_DURATION = 24 * 60*60
end