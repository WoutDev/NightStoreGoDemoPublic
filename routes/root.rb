class App < Sinatra::Base
  get '/' do
    if params.has_key?('location') && params['location'].strip != ''
      location = Rack::Utils.escape_html(params['location'])
      postcode = (Integer(location) rescue false) && location.to_i.between?(1000, 10000)

      if postcode
        @shops = Shop.where("address.postcode" => location.to_i).sort(:min_price).all
      else
        @shops = Shop.where("address.city" => location.downcase).sort(:min_price).all
      end
    end

    @shops ||= Shop.sort(:min_price).all
    erb :index
  end

  get '/:city' do
    @shops = Shop.where("address.city" => Rack::Utils.escape_html(params['city'])).all
    erb :index
  end
end