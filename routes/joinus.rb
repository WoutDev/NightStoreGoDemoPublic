class App < Sinatra::Base
  get '/joinus' do
    @page = 'joinus'
    erb :joinus
  end
end