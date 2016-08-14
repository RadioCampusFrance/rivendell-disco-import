module Rivendell::Import::Tasking
  module Tags

    def raw_tags
      read_attribute :tags
    end

    def tags
      @tags ||= (raw_tags ? raw_tags.split(",") : [])
    end

    def tag(tag)
      self.tags << tag
    end

    def write_tags
      write_attribute :tags, tags.join(',') if @tags
    end

    def self.included(base)
      base.class_eval do
        before_save :write_tags        
      end
    end

  end
end
