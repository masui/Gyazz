require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'backports'
require 'rss/maker'
require 'set'

$:.unshift File.dirname(__FILE__)

## load libraries
require 'lib/config'
require 'lib/init'
require 'lib/pair'
require 'lib/keyword'
require 'lib/png'
require 'lib/auth'
require 'lib/time'
require 'lib/md5'

## load models
require 'models/attr'
require 'models/page'
require 'models/wiki'

## load helpers
require 'helpers/helper'

require 'controllers/gyazz'

run Sinatra::Application
