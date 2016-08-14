module Rivendell::Import::Tasking
  module Cart

    def raw_cart
      read_attribute :cart
    end

    def cart
      @cast ||= Rivendell::Import::Cart.new(self).tap do |cart|
        cart.from_json(raw_cart, false) if raw_cart
      end
    end

    def write_cart
      write_attribute :cart, (cart.present? ? cart.to_json : nil)
    end

    def self.included(base)
      base.class_eval do
        before_save :write_cart
      end
    end

  end
end
