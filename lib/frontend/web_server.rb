require 'sinatra/base'
require 'erubis'
require_relative '../database/database.rb'

module Frontend
  class WebServer < Sinatra::Base
    set :bind, "0.0.0.0"
    
    def initialize(app = nil)
      super(app)
      
      @index = Common::IndexFile.new(Config.paths.index)
      @db    = Database::Backend.new
    end
    
    get '/' do
      render_page("index.erb", {title: "Durchsuche das Internet"})
    end

    get '/search' do
      start_time = Time.now
      query = params[:query]
      page  = params[:page].to_i
      
      search = Frontend::SearchRunner.new(@index, @db, query)
      search.run
      
      if page < 1
        page = 1
      elsif page > search.pages_count
        page = search.pages_count
      end
      
      results = search.page(page)
      
      duration  = Time.now - start_time
      pagination = Frontend::WebPagination.new(search.pages_count, page, query)
      render_page("results.erb", {query: query, duration: duration, results: results, results_count: search.results_count, pagination: pagination})
    end

    private
    
    def render_page(page, vars={})
      vars = {title: ""}.merge(vars)
      vars[:content] = Erubis::Eruby.new(File.read("ui/#{page}")).result(vars)
      Erubis::Eruby.new(File.read("ui/layout.erb")).result(vars)
    end
  end
end
