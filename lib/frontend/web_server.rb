require 'sinatra/base'
require 'oj'
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
      render_page("index.erb", {title: "BREAKSEARCH"})
    end

    get '/search' do
      start_time = Time.now
      query = params[:query]
      page  = params[:page].to_i
      
      if page < 1
        page = 1
      elsif page > search.pages_count
        page = search.pages_count
      end
      
      search  = get_search(query)
      results = search.page(page)      
      duration  = Time.now - start_time
      pagination = Frontend::WebPagination.new(search.pages_count, page, query)
      render_page("results.erb", {query: query, duration: duration, results: results, results_count: search.results_count, pagination: pagination})
    end
    
    get '/search.json' do
      query = params[:query]
      page  = params[:page].to_i
      
      results = get_results(query, page).map do |metadata, score|
        {"title" => metadata.title, "score" => score, "url" => {"decoded" => metadata.url.decoded, "encoded" => metadata.url.encoded}}
      end
      
      content_type :json, "charset" => "utf-8"
      Oj.dump({"results" => results})
    end

    private
    def get_search(query)
      search = Frontend::SearchRunner.new(@index, @db, query)
      search.run
      search
    end
    
    def get_results(query, page)
      search = get_search(query)
      if page < 1
        page = 1
      elsif page > search.pages_count
        page = search.pages_count
      end
      search.page(page)
    end
    
    def render_page(page, vars={})
      vars = {title: ""}.merge(vars)
      vars[:content] = Erubis::Eruby.new(File.read("ui/#{page}")).result(vars)
      Erubis::Eruby.new(File.read("ui/layout.erb")).result(vars)
    end
  end
end
