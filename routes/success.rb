class App < Sinatra::Base
  get '/succes' do
    erb :success
  end
end