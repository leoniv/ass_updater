if ENV["SIMPLECOV"] then
  require "simplecov"
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ass_updater'

require 'minitest/autorun'
