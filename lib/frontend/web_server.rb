############################################################################################
# Der Webserver stellt die Schnittstelle zwischen dem Webbrowser des Nutzers und dem       #
# SearchRunner da. Die Resultate werden in Templates im Verzeichnis ui geladen und dem     #
# Nutzer angezeigt. Der Server verwendet die Sinatra Library um einfach einen Server zu    #
# implementieren.                                                                          #
############################################################################################
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

      search  = get_search(query)
      results = search.page(page)
      duration  = Time.now - start_time
      pagination = Frontend::WebPagination.new(search.pages_count, page, query)

      view_vars = {}
      view_vars[:query] = query
      view_vars[:duration] = duration
      view_vars[:results] = results
      view_vars[:results_count] = search.results_count
      view_vars[:pagination] = pagination
      render_page("results.erb", view_vars)
    end

    private
    def get_search(query)
      search = Frontend::SearchRunner.new(@index, @db, query)
      search.run
      search
    end

    def render_page(page, vars={})
      vars[:title] ||= "BREAKSEARCH"
      vars[:content] = Erubis::Eruby.new(File.read("ui/#{page}")).result(vars)
      Erubis::Eruby.new(File.read("ui/layout.erb")).result(vars)
    end
  end
end
