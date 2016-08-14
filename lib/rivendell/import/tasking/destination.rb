module Rivendell::Import::Tasking
  module Destination

    def destination
      read_attribute(:destination) or
        write_attribute(:destination, calculate_destination)
    end

    def reset_destination!
      write_attribute :destination, nil
    end

    def self.included(base)
      base.class_eval do
        before_save :destination, :on => :create
      end
    end

    def calculate_destination
      if cart.number
        "Cart #{cart.number}"
      elsif cart.group
        "Cart in group #{cart.group}" 
      end
    end

  end
end
