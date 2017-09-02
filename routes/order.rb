require 'date'

class App < Sinatra::Base
  helpers Sinatra::Param

  get '/bestel' do
    @shop = session[:basket][0][0].shop

    if session[:basket].inject(0) { |sum, item| sum += item[0].price * item[1] } < @shop.min_price || !@shop.opening_hours.in_hours?(Time.now)
      redirect '/winkelmand' and return
    end

    @extra_scripts = "<script src='#{request.base_url}/js/order.js'></script>"

    @token = Tokens.gen_token

    erb :order
  end

  before '/bestel' do
    if session[:basket] == nil || session[:basket].empty?
      redirect '/'
    end
  end

  after '/bestel' do
    if request.request_method == "GET"
      session[:order] = {}
    end
  end

  post '/bestel' do
    begin
      param :street, String, required: true, blank: false, format: /^.{3,75}$/
      param :housenumber, String, required: true, blank: false, format: /^.{1,10}$/
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :phone, String, required: true, blank: false, format: /^.{10}$/
      param :comments, String, required: false, format: /^.{0,250}$/
      param :policies, Boolean, required: true, blank: false, is: true
      param :token, String, required: true, blank: false, format: /^.{20}$/

      Float(params['phone'])
    rescue Exception => e
      flash[:warning] = <<-WARNING
      <strong>Oops!</strong> Je hebt niet alle velden correct ingevuld. Let zeker op onderstaande:\n
      <ul>
        <li>Alle velden zijn verplicht (buiten opmerkingen)</li>
        <li>Telefoon moet in de juiste formaat zijn (<strong>zonder</strong> spaties): 04xxxxxxxx</li>
        <li>Opmerkingen maximum 250 karakters</li>
      </ul>
      WARNING
      redirect '/bestel'
    ensure
      @street = session[:order][:street] = Rack::Utils.escape_html(params[:street])
      @housenumber = session[:order][:housenumber] = Rack::Utils.escape_html(params[:housenumber])
      @postcode = session[:order][:postcode] = Rack::Utils.escape_html(params[:postcode])
      @phone = session[:order][:phone] = authenticated? ? session[:user].phone : Rack::Utils.escape_html(params[:phone])
      @comments = session[:order][:comments] = Rack::Utils.escape_html(params[:comments])
    end

    unless Tokens.check_token(params['token'])
      redirect '/' and return
    end

    @shop = session[:basket][0][0].shop

    total = session[:basket].inject(0) { |sum, item| sum += item[0].price * item[1] }

    if total < @shop.min_price || !@shop.opening_hours.in_hours?(Time.now)
      redirect '/winkelmand' and return
    end

    Tokens.remove_token(params['token'])

    products = {}
    session[:basket].each do |item|
      products.store(item[0].id.to_s, {name: item[0].name, quantity: item[1]})
    end

    session[:basket].clear

    Thread.new do
      products_readable = ""
      products.each {|k,v| products_readable += (v[:quantity].to_s + 'x ' + v[:name] + "\n")}

      user_phone = authenticated? ? session[:user].phone : 'n/a'

      order = Order.create(phone: @phone, comments: @comments, ip: request.ip, products: products, total: total, address: {street: @street, housenumber: @housenumber, postcode: @postcode}, shop: @shop, user_phone: user_phone)

      email = <<-EMAIL
      Bestelling: #{order.id}
      Totaal bedrag: €#{'%.02f' % total}
      Telefoon klant: #{@phone}\n
      
      #{products_readable}
  
      Opmerking(en): #{@comments == '' ? '--- geen ---' : @comments}
  
      Adres voor levering:
      Straat en nummer: #{@street} #{@housenumber}
      Postcode: #{@postcode}\n
  
      Bestelling werd geplaatst om: #{order.created_at.strftime("%d/%m/%Y %H:%M")}
      De klant zal de bestelling verwachten rond: #{(order.created_at + @shop.estimate_delivery_in_minutes * 60).strftime("%d/%m/%Y %H:%M")}
      EMAIL

      send_mail(@shop.email, 'orders@email.com', (total >= 100 ? '!!! ' : '') + 'Bestelling: ' + order.id, email)
      send_mail('orders@email.com', 'orders@email.com', (total >= 100 ? '!!! ' : '') + 'Bestelling: ' + order.id, email)

      session[:order].clear
    end

    redirect '/succes'
  end
end