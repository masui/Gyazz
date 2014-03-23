require 'minitest/autorun'
require 'bundler/setup'
require 'sinatra'
require 'rack/test'

ENV["RACK_ENV"] = "test"

$:.unshift File.expand_path '../', File.dirname(__FILE__)

## load libraries
require 'lib/config'
require 'lib/init'
require 'lib/png'
require 'lib/keyword'
require 'lib/pair'
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
