# coding: utf-8
require 'sinatra/base'
require 'sinatra/partial'
require 'slim'

class ApplicationController < Sinatra::Base
  helpers ApplicationHelpers
  register Sinatra::Partial
  set :partial_template_engine, :slim
  
  set :views, File.expand_path('../../views', __FILE__)
  set :public_folder, File.expand_path('../../../public', __FILE__)

  use Rack::Session::Pool, :expire_after => 3600
  set :session_secret, 'sjscb'
  set :sessions, :expire_after => 3600
  
  configure :production, :development do
    enable :logging
  end

  Slim::Engine.options[:pretty] = true
  not_found do
    slim :not_found, :locals => { :title => '找不到页面！' }
  end
end
