require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'backports'
  
require File.expand_path 'gyazz', File.dirname(__FILE__)

run Sinatra::Application
