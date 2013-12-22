require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'backports'

$:.unshift File.dirname(__FILE__)

require 'lib/lib'
require 'lib/config'
require 'lib/search'
require 'lib/writedata'
require 'lib/readdata'
require 'lib/edit'
require 'lib/pair'
require 'lib/keyword'
require 'lib/related'
require 'lib/page'
require 'lib/attr'
require 'lib/png'
require 'lib/history'
require 'lib/rss'
require 'lib/access'
require 'lib/auth'
require 'lib/contenttype'

require 'helpers/helper'

require 'controllers/gyazz'

run Sinatra::Application
