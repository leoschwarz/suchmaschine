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
      render_page("index.erb")
    end
    
    get '/*.js' do |name|
      # Verhindern, dass das Verzeichnis gewechselt wird
      name.gsub!(/\.+/, ".")
      name.delete!("/")
      
      content_type :js
      if File.exist?("ui/#{name}.js")
        File.read("ui/#{name}.js")
      else
        status 404
        ""
      end
    end

    get '/search' do
      start_time = Time.now
      query = params[:query]
      page  = params[:page].to_i
      render_layout = (params[:render_layout] != "false") # TODO implementieren, und nacher in die resultatseite laden...
      
      search  = get_search(query)
      
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
    def get_search(query)
      search = Frontend::SearchRunner.new(@index, @db, query)
      search.run
      search
    end
    
    def render_page(page, vars={})
      vars[:content] = Erubis::Eruby.new(File.read("ui/#{page}")).result(vars)
      Erubis::Eruby.new(File.read("ui/layout.erb")).result(vars)
    end
  end
end
