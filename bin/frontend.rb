#!/usr/bin/env ruby
require_relative '../lib/common/common.rb'
require_relative '../lib/frontend/frontend.rb'
require 'sinatra/base'
require 'erubis'

module Frontend
  include Common::DatabaseClient

  class WebServer < Sinatra::Base
    set :views, File.join(File.dirname(__FILE__), "../ui/")
    set :bind, "0.0.0.0"

    get '/' do
      render_page("index.erb", {title: "Durchsuche das Internet"})
    end

    get '/search' do
      query = params[:query]
      search = Frontend::SearchRunner.new(query)
      search.run
      render_page("results.erb", {title: "#{search.results_count} Resultate gefunden:", results: search.results})
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
