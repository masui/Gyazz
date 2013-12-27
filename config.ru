require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'backports'

$:.unshift File.dirname(__FILE__)

require 'lib/db'
require 'lib/config'
require 'lib/search'
require 'lib/edit'
require 'lib/pair'
require 'lib/keyword'
require 'lib/related'
require 'lib/page'
require 'lib/png'
require 'lib/history'
require 'lib/rss'
require 'lib/auth'
require 'lib/time'

require 'lib/wiki'
require 'lib/md5'

require 'helpers/helper'

require 'controllers/gyazz'

run Sinatra::Application
