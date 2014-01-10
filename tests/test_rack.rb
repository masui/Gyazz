# -*- coding: utf-8 -*-
require File.expand_path 'test_helper', File.dirname(__FILE__)

# ENV['RACK_ENV'] = 'test'

class TestTest < MiniTest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_test
    get '/Gyazz'
    assert last_response.ok?
    assert last_response.body.index('Gyazz ページリスト')
  end

#
#  def test_it_says_hello_world
#    get '/'
#    assert last_response.ok?
#    assert_equal 'Hello World', last_response.body
#  end
#
#  def test_it_says_hello_to_a_person
#    get '/', :name => 'Simon'
#    assert last_response.body.include?('Simon')
#  end
end
