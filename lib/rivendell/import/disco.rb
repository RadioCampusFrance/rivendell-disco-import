module Rivendell::Import
  class Disco
    include Singleton
    include HTTMultiParty

    @@url = nil
    cattr_accessor :url

    @@dropbox_path = nil
    cattr_accessor :dropbox_path

    @@archive_path = nil
    cattr_accessor :archive_path

    @@default_to_prepare = nil
    cattr_accessor :default_to_prepare

    def to_prepare
      false or default_to_prepare
    end

    def initialize
      require 'fileutils'
      if @@url and @@dropbox_path
        @tasks = Tasks.new
      end
    end

    def find_staging_discs
      found = {}
      Dir[::File.join([@@dropbox_path, "**/*"])].each do |path|
        if ::File.directory?(path)
          title = ::File.basename(path)
          m = title.match('^\[([0-9]+)\].*')
          if m
            found[m[1].to_i] = title
          end
        end
      end
      return found
    end

    def find_path_by_id(id)
      Dir[::File.join([@@dropbox_path, "**/*"])].each do |path|
        if ::File.directory?(path)
          title = ::File.basename(path)
          m = title.match('^\['+id+'\].*')
          return path if m
        end
      end
      return nil
    end

    def find_staged_disc(id)
      base = find_path_by_id(id)
      return nil if !base
      files = {}

      Dir.entries(base).each do |path|
        title = ::File.basename(path)
        m = title.match('([1-9]+[0-9]*).*') # /!\ no starting 0
        if m
          files[m[1]] = title
        end
      end

      return {
        :path => base,
        :basename => ::File.basename(base),
        :files => files
      }
    end

    def get_infos(id)
      uri = url + (url.match('/$') ? '' : '/') + "cd/" + id + "/rivendellInfo"

      Rivendell::Import.logger.debug "GET "+uri
      response = self.class.get uri
      response.error! unless response.success?
      response.parsed_response
    end

    def missing_tracks(staging, info)
      info["tracks"].each do |num, track|
        if track["rivendell"] && !staging[:files].key?(num)
          return true
        end
      end
      return false
    end

    def uses_default_names(info)
      info["tracks"].each do |num, track|
        if !track["title"].match(/^Track [0-9]+/)
          return false
        end
      end
      return true
    end

    def import(id)
      files = find_staged_disc(id)
      info = get_infos(id)

      info["tracks"].each do |num, track|
        if track["rivendell"]
          fullpath = ::File.join(files[:path], files[:files][num])

          Rivendell::Import.logger.debug "Preparing "+fullpath
          Rivendell::Import.logger.debug track["artist"] +" - "+track["title"]+info["scheduler_codes"].to_s

          Rivendell::Import::Task.create({:file => (Rivendell::Import::File.new fullpath)}).tap do |task|
            Rivendell::Import.logger.debug "Created task #{task.inspect}"
            task.prepare do
              cart.scheduler_codes = info["scheduler_codes"]
              cart.album = info["title"]
              cart.title = track["title"]
              cart.artist = track["artist"]
            end
            task.prepare(&to_prepare) if to_prepare

            task.run

            if !task.ran?
              throw new Exception(fullpath)
            end
          end
        end
      end

      if @@archive_path
        FileUtils.mv(files[:path], ::File.join(@@archive_path, files[:basename]))
      else
        FileUtils.remove_dir(files[:path])
      end
    end


  end
end
