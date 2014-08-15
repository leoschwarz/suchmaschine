require './config/config.rb'


command = <<-BASH
export PGPASSWORD=#{Crawler.config.database.password} ;
pg_dump --username=#{Crawler.config.database.user} --host=#{Crawler.config.database.host} --schema-only #{Crawler.config.database.name} > db/schema.sql
BASH

exec command
