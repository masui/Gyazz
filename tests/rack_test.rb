# -*- coding: utf-8 -*-
require 'rubygems'
require 'sinatra'
require File.expand_path '../gyazz', File.dirname(__FILE__)
require 'test/unit'
require 'rack/test'

# ENV['RACK_ENV'] = 'test'

class TestTest < Test::Unit::TestCase
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
