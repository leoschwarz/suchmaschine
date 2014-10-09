#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require 'sinatra/base'
require 'erubis'

module Frontend
  include Common::DatabaseClient

  class WebServer < Sinatra::Base
    set :views, File.join(File.dirname(__FILE__), "../ui/")
    set :bind, "0.0.0.0"

    get '/' do
      render_page("index.erb", {title: "Das Internet"})
    end

    get '/search' do
      query = params[:query]
      docinfos = Frontend::Database.index_get(query)
      results  = docinfos[0...10].map{|docinfo| Common::URL.stored(Frontend::Document.load(docinfo).url).encoded}

      render_page("results.erb", {title: "#{docinfos.size} Resultate gefunden:", results: results})
    end

    def render_page(page, vars={})
      vars = {title: ""}.merge(vars)
      vars[:content] = Erubis::Eruby.new(File.read("ui/#{page}")).result(vars)
      Erubis::Eruby.new(File.read("ui/layout.erb")).result(vars)
    end
  end
end

if __FILE__ == $0
  Frontend::WebServer.run!
end
