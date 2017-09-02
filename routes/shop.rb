class App < Sinatra::Base
  helpers Sinatra::Param

  get '/winkel/:postcode/:slug' do
    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      erb :not_found
    end

    @extra_scripts = "<script src='#{request.base_url}/js/shop.js'></script>"

    postcode = params['postcode'].to_i

    slug = Rack::Utils.escape_html(params['slug'])

    @shop = Shop.where("address.postcode" => postcode, :slug => slug).first

    if @shop == nil
      erb :not_found
    else
      @categories = []
      @shop.products.each {|p| @categories << p.category unless @categories.include?(p.category) }
      erb :shop
    end
  end

  post '/winkel/:postcode/:slug/setitem/:product_id/:amount' do
    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
      param :product_id, String, required: true, blank: false, format: /^.{24,24}$/
      param :amount, Integer, required: true, blank: false, min: 0, max: 100
    rescue
      halt 400
    end

    postcode = params['postcode'].to_i
    slug = Rack::Utils.escape_html(params['slug'])
    product_id = Rack::Utils.escape_html(params['product_id'])
    amount = params['amount'].to_i

    @shop = Shop.where("address.postcode" => postcode, :slug => slug).first

    if @shop == nil
      halt 404
    else
      unless @shop.opening_hours.in_hours?(Time.now)
        halt 400
      end

      @product = Product.where('id' => product_id, :shop_id => @shop.id).first

      if @product == nil
        halt 404
      else
        session[:basket] ||= []

        if session[:basket].count {|item| item[0].shop.id != @product.shop.id} >= 1
          halt 406
        end

        index = session[:basket].find_index { |item| item[0].id == @product.id }

        # Delete logic
        if amount == 0
          unless index == nil
            session[:basket].delete_at(index)
            halt 200
          end

          halt 404
        end

        if index == nil
          session[:basket] << [@product, amount]
        else
          session[:basket][index][1] = amount
        end

        halt 200
      end
    end
  end

  get '/winkel/:postcode/:slug/emptybasket' do
    if session[:basket] == nil || session[:basket].empty?
      redirect '/' and return
    end

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      halt 400
    end

    postcode = params['postcode'].to_i
    slug = Rack::Utils.escape_html(params['slug'])

    @shop = Shop.where("address.postcode" => postcode, :slug => slug).first

    if @shop == nil
      halt 404
    else
      if session[:basket][0][0].shop.id == @shop.id
        session[:basket].clear
        redirect back
      else
        redirect '/'
      end
    end
  end

  get '/winkel/:postcode/:slug/getbasket/:product_id' do
    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
      param :product_id, String, required: true, blank: false, format: /^.{24,24}$/
    rescue
      halt 400
    end

    postcode = params['postcode'].to_i
    slug = Rack::Utils.escape_html(params['slug'])
    product_id = Rack::Utils.escape_html(params['product_id'])

    @shop = Shop.where("address.postcode" => postcode, :slug => slug).first

    if @shop == nil
      halt 404
    else
      @product = Product.where('id' => product_id, :shop_id => @shop.id).first

      if @product == nil
        halt 404
      else
        if session[:basket] == nil || session[:basket].count == 0
          return gen_product_json(@product, 0)
        end

        index = session[:basket].find_index { |item| item[0].id == @product.id }

        if index == nil
          gen_product_json(@product, 0)
        else
          amount = session[:basket][index][1]
          gen_product_json(@product, amount)
        end
      end
    end
  end

  get '/winkel/:postcode/:slug/getbasket' do
    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      halt 400
    end

    postcode = params['postcode'].to_i
    slug = Rack::Utils.escape_html(params['slug'])

    @shop = Shop.where("address.postcode" => postcode, :slug => slug).first

    if @shop == nil
      halt 404
    else
      unless @shop.opening_hours.in_hours?(Time.now)
        return '{"error": "INVALID"}'
      end

      if session[:basket] == nil || session[:basket].empty?
        return "{}"
      end

      if session[:basket][0][0].shop.id != @shop.id
        return '{"error": "INVALID"}'
      end

      products = []

      session[:basket].each do |item|
        products << [item[0].name, item[0].id, item[0].price, item[0].description, item[0].min_age, item[1], @shop.slug]
      end

      JSON.generate(products)
    end
  end

  private
    def gen_product_json(product, amount)
      JSON.generate({:name => product.name, :price => product.price, :description => product.description, :min_age => product.min_age, :amount => amount})
    end
end