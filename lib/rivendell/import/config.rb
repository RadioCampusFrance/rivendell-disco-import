module Rivendell::Import
  class Config

    def to_prepare(&block)
      Base.default_to_prepare = block
    end

    def rivendell
      @rivendell ||= Rivendell.new
    end

    def disco_url=(url)
      Disco.url = url
    end

    def dropbox_path=(url)
      Disco.dropbox_path = url
    end

    def archive_path=(url)
      Disco.archive_path = url
    end

    alias_method :xport_options, :rivendell

    class Rivendell

      def host=(host)
        Task.default_xport_options[:host] = host
      end

      def login_name=(login_name)
        Task.default_xport_options[:login_name] = login_name
      end
      alias_method :user=, :login_name=

      def password=(password)
        Task.default_xport_options[:password] = password
      end

      def db_url=(url)
        Database.url = url
      end

    end

  end
end
