require 'sinatra'
require 'sinatra/flash'

require 'will_paginate'
require 'will_paginate/active_record'

module Rivendell::Import
  class Application < Sinatra::Application
    enable :sessions

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

    get '/disco_staging' do
      erb :disco_awaiting, :locals => { :discs => Disco.instance.find_staging_discs}
    end

    get '/disco_confirm_import/:id' do
      staging = Disco.instance.find_staged_disc(params['id'])
      raise Sinatra::NotFound if !staging

      info = Disco.instance.get_infos(params['id'])
      if info.empty?
        flash[:failure] = "Le disque "+staging[:basename]+" n'a pas été trouvé dans Disco, vérifiez la dropbox et le numéro."
        redirect "/disco_staging", 302
      end

      if Disco.instance.uses_default_names(info)
        flash.now[:warning] = "Attention les titres de pistes entrés dans Disco sont les titres par défaut."
      end

      if info[:scheduler_codes].empty?
        flash.now[:warning] = "Attention ce disque n'est pas enregistré avec un genre qui corresponde à un Scheduler Code."
      end

      if Disco.instance.missing_tracks(staging, info)
        flash.now[:failure] = "Attention des titres prévus pour Rivendell dans Disco ne sont pas dans le répertoire."
      end

      erb :disco_confirm_import, :locals => {
        :files => staging[:files],
        :id => params['id'],
        :info => info,
      }
    end

    get '/disco_import/:id' do
      Disco.instance.import(params['id'])
      flash[:success] = "Le disque "+params['id']+" a été importé."
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
