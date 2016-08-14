class Rivendell::API::MockXport

  def carts
    @carts ||= []
  end

  def list_carts(options = {})
    result = carts
    if group = options[:group]
      result = result.select { |cart| cart.group == group }
    end
    result
  end

  def reset!
    @carts = nil
  end

end

class Rivendell::Import::Task

  @@mock_xport = Rivendell::API::MockXport.new
  cattr_accessor :mock_xport

  def xport
    mock_xport
  end

end

Before do
  Rivendell::Import::Task.mock_xport.reset!
end
