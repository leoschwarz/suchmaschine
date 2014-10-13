#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require_relative '../lib/database/database'

# API Dokumentation ::
#
# [...] = Weitere Tab-getrennte Werte(paare)
#
# DOWNLOAD_QUEUE_INSERT\tURL1[...]
# DOWNLOAD_QUEUE_FETCH
## INDEX_QUEUE_INSERT\tDOCINFO1[...]
## INDEX_QUEUE_FETCH
## INDEX_APPEND\tWORD1\tPOS1:DOC_HASH1[...] -> Fügt die jeweiligen DOC Einträge zu den Index Files hinzu.
## INDEX_GET\tWORD
# CACHE_SET\tKEY\tVALUE
# CACHE_GET\tKEY
# DOCUMENT_SET\tHASH\tDOCUMENT
# DOCUMENT_GET\tHASH
# METADATA_SET\tHASH\tDOCUMENT_INFO -> Dies speichert die Dokumentinfo UND gibt dieses in die INDEX Warteschlange auf.
# METADATA_GET\tHASH

if __FILE__ == $0
  Database::Server.new.start
end
