require 'minitest/autorun'
require 'sinatra'
require 'rack/test'

$:.unshift File.expand_path '../', File.dirname(__FILE__)
require 'lib/config'
require 'lib/lib'
require 'lib/contenttype'
require 'lib/png'
require 'lib/keyword'
require 'lib/pair'
require 'controllers/gyazz'