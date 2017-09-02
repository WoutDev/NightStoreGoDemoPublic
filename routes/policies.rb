class App < Sinatra::Base
  get '/voorwaarden' do
    erb :policies
  end
end