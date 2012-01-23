require 'rubygems'
require 'text_attribute'
require 'rr'

RSpec.configure do |c|
  c.mock_with :rr

  c.before(:each) do
    $text_memory_store = {}
  end
end
