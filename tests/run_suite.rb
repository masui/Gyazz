require File.expand_path 'test_helper', File.dirname(__FILE__)

Dir.glob(File.expand_path('../**/*_test.rb', __FILE__)).each { |test| require test }
Dir.glob(File.expand_path('../**/test_*.rb', __FILE__)).each { |test| require test }