require 'sinatra/param'

class App < Sinatra::Base
  set raise_sinatra_param_exceptions: true
end