require 'sinatra/base'
require 'erubis'

module Frontend
  class WebServer < Sinatra::Base
    set :views, File.join(File.dirname(__FILE__), "../ui/")
    set :bind, "0.0.0.0"

    get '/' do
      render_page("index.erb", {title: "Durchsuche das Internet"})
    end

    get '/search' do
      start_time = Time.now
      query = params[:query]
      page  = params[:page].to_i
      
      search = Frontend::SearchRunner.new(query)
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

    def render_page(page, vars={})
      vars = {title: ""}.merge(vars)
      vars[:content] = Erubis::Eruby.new(File.read("ui/#{page}")).result(vars)
      Erubis::Eruby.new(File.read("ui/layout.erb")).result(vars)
    end
  end
end
