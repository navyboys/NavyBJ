require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do
  erb :form
end

post '/my_action' do
  "Welcome! " + params[:user_name]
end