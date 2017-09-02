class App < Sinatra::Base
  get '/diensten' do
    @page = 'services'
    erb :services
  end
end