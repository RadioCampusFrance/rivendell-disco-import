module Rivendell::Import
  class CartFinder

    def find_all_by_title(string, options = {})
      normalizer = options.delete(:normalizer) || Proc.new { |id| id }

      string = normalizer.call(string)
      carts(options).select do |cart|
        normalizer.call(cart.title) == string
      end
    end
    
    def default_normalizer
      Proc.new do |string|
        ActiveSupport::Multibyte::Chars.new(string).normalize(:kd).gsub(/[^\x00-\x7F]/n,'').downcase.to_s.gsub(/[^a-z0-9]/," ").gsub(/[ ]+/," ")
      end
    end

    def find_by_title(string, options = {})
      matching_carts = find_all_by_title(string, options)

      if matching_carts.blank?
        matching_carts = find_all_by_title(string, options.merge(:normalizer => default_normalizer))
      end

      matching_carts.first if matching_carts.one?
    end

    class ByApi < CartFinder

      attr_accessor :xport

      def initialize(xport)
        @xport = xport
      end

      def cache
        clear if purged_at < time_to_live.ago
        @cache ||= {}
      end

      def clear
        @cache = nil
      end

      @@time_to_live = 600
      cattr_accessor :time_to_live
      
      attr_accessor :purged_at
      
      def purged_at
        @purged_at ||= Time.now
      end
      
      def carts(options = {})
        cache[options.to_s] ||= xport.list_carts(options)
      end

    end

  end
end
