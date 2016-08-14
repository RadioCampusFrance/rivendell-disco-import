require 'simplecov'

if ENV['SIMPLECOV_RCOV_OUTPUT']
  require 'simplecov-rcov'

  class SimpleCov::Formatter::MergedFormatter
    def format(result)
      SimpleCov::Formatter::HTMLFormatter.new.format(result)
      SimpleCov::Formatter::RcovFormatter.new.format(result)
    end
  end
  SimpleCov.formatter = SimpleCov::Formatter::MergedFormatter
end

SimpleCov.start do
  add_filter "/spec/"
  add_filter "/db/"
  add_filter "/vendor/"
end
