def import
  @import ||= Rivendell::Import::Base.new.tap do |import|

  end
end

class Array

  def as_hash
    Hash[self]
  end

end

Given /^a cart "(.*?)" exists with (.*)$/ do |number, fields|
  attributes = fields.scan(/\ *(([^:]+):"([^\"]+)",?)/).map do |part, name, value|
    [name, value]
  end.as_hash

  cart = Rivendell::API::Cart.new(attributes.merge(:number => number))
  Rivendell::Import::Task.mock_xport.carts << cart
end

Given /^a configuration with this prepare block$/ do |code|
  import.to_prepare = eval  "lambda { |file| " + code + " }"
end

When /^a file "([^"]*)" is imported$/ do |file|
  FileUtils.touch file, :mtime => Time.now - 15
  import.file file
end

Then /^the task should have destination "([^"]*)"$/ do |destination|
  import.tasks.pop.destination.should == destination
end

Then /^the task should have tag "([^"]*)"$/ do |tag|
  import.tasks.pop.tags.should include(tag)
end

Then /^the task should have status "([^"]*)"$/ do |status|
  Rivendell::Import::Task.last.status.should == status
end
