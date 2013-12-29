require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'backports'
require 'rss/maker'

$:.unshift File.dirname(__FILE__)

require 'lib/config'
require 'lib/pair'
require 'lib/keyword'
require 'lib/related'
require 'lib/png'
require 'lib/visualize'
require 'lib/rss'
require 'lib/auth'
require 'lib/time'
require 'lib/attr'

require 'lib/page'
require 'lib/wiki'
require 'lib/md5'

require 'helpers/helper'

require 'controllers/gyazz'

run Sinatra::Application
