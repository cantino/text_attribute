require 'rubygems'
require 'text_attribute'
require 'rr'

RSpec.configure do |c|
  config.mock_with :rr

  config.before(:each) do
    $text_memory_store = {}
  end
end
