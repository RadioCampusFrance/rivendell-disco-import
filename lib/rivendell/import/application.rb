require 'sinatra'
require "sinatra/reloader" if development?

require 'will_paginate'
require 'will_paginate/active_record'

module Rivendell::Import
  class Application < Sinatra::Application

    set :public_folder, ::File.expand_path('static', ::File.dirname(__FILE__))
    # set :static_cache_control, [:public, :max_age => 3600]
    set :bind, '0.0.0.0'

    get '/' do
      redirect "/tasks", 302
    end

    get '/tasks' do
      tasks = self.tasks.paginate(:page => params[:page], :per_page => (params[:per_page] or 15))
      tasks = tasks.search(params[:search]) if params[:search]
      erb :index, :locals => { :tasks => tasks }
    end

    get '/tasks.json' do
      tasks.to_json
    end

    def config_loader
      settings.config_loader
    end

    def edit_config
      erb :config, :locals => { :config => config_loader.current_config }
    end

    get '/config' do
      edit_config
    end

    post '/config' do
      config_loader.save params["config"]
      edit_config
    end

    def tasks
      Task.order("updated_at DESC")
    end

    def import
      settings.import # a Rivendell::Import::Base use its 'file' method, then its tasks.run

      ########" TODO: move this to Disco object, make it a singleton, change config accordingly
    end

    get '/disco_staging' do
      erb :disco_awaiting, :locals => { :discs => {123 => "test", 234 => "lol"}}
    end

    get '/disco_confirm_import/:id' do
      erb :disco_confirm_import, :locals => {:id => params['id']}
    end

    get '/disco_import/:id' do
      redirect "/disco_staging", 302
    end

    helpers do
      def distance_of_time_in_words_from_now(time)
        distance = Time.now - time

        if distance < 43200 # less than 12 hours
          time.strftime("%H:%M")
        else
          time.strftime("%d/%m")
        end
      end

      def truncate_filename(path, length)
        path = path.to_s

        if path.size < length
          path
        else
          path[0..length] + "..."
        end
      end

    end

  end
end
