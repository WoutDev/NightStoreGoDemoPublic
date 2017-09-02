class App < Sinatra::Base
  get '/winkelmand' do
    @page = 'basket'

    @extra_scripts = "<script src='#{request.base_url}/js/basket.js?v=#{Random.rand(1000)}'></script>"

    if session[:basket] != nil && !session[:basket].empty?
      @shop = session[:basket][0][0].shop
    end

    erb :basket
  end
end