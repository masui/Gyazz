require 'minitest/autorun'
require 'sinatra'
require 'rack/test'

$:.unshift File.expand_path '../', File.dirname(__FILE__)
require 'lib/config'
require 'lib/lib'
require 'lib/png'
require 'lib/keyword'
require 'lib/pair'
require 'lib/rss'
require 'lib/search'
require 'controllers/gyazz'
