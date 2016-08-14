# Find Carts using a direct database access.
#
# Provided to workaround actual accent problems experienced with Rivendell API.
module Rivendell::Import
  class CartFinder::ByDb < CartFinder

    def carts(options = {})
      Database.init

      query_options = { :fields => [ :number, :title ] }

      if options[:group]
        query_options[:group_name] = options[:group]
      end

      Rivendell::DB::Cart.all(query_options)
    end

  end
end
