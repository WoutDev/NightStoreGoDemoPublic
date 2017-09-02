class App < Sinatra::Base
  get '/privacy' do
    erb :privacy
  end
end