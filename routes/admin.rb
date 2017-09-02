class App < Sinatra::Base
  helpers Sinatra::Param
  helpers Rack::Recaptcha::Helpers

  ## Admin Dashboard

  get '/admin' do
    protected!

    @admin_page = 'dashboard'
    erb :admin
  end

  ## Shop Management

  get '/admin/winkels' do
    protected!

    @admin_page = 'shops'
    @shops = Shop.all

    erb :admin_shops
  end

  post '/admin/winkel' do
    protected!

    begin
      param :name, String, required: true, blank: false
      param :min_price, Float, required: true, blank: false
      param :email, String, required: true, blank: false, format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      param :estimate_delivery_minutes, Integer, required: true, blank: false
      param :street, String, required: true, blank: false
      param :city, String, required: true, blank: false
      param :province, String, required: true, blank: false
    rescue Exception => e
      flash[:warning] = 'Er is iets misgegaan tijdens het aanmaken van de winkel. Wees zeker dat alles correct is ingevuld en dat de naam uniek is. (denk aan het formaat van een email en dergelijke)'

      redirect '/admin/winkels'
    end

    if Shop.where(name: params['name']).all.count >= 1
      flash[:warning] = 'Er is iets misgegaan tijdens het aanmaken van de winkel. Wees zeker dat alles correct is ingevuld en dat de naam uniek is. (denk aan het formaat van een email en dergelijke)'

      redirect '/admin/winkels'
    end

    @shop = Shop.create(name: params['name'], slug: params['name'].slugify, min_price: params['min_price'].to_f, email: params['email'],
                        estimate_delivery_in_minutes: params['estimate_delivery_minutes'].to_i, address: {address: params['street'],
                        city: params['city'].downcase, postcode: params['postcode'].to_i, province: params['province']},
                        opening_hours: Biz::Schedule.new { |config| config.hours = {mon: {'18:00' => '24:00', '00:00' => '07:00'},
                                                                                    tue: {'18:00' => '24:00', '00:00' => '07:00'},
                                                                                    wed: {'18:00' => '24:00', '00:00' => '07:00'},
                                                                                    thu: {'18:00' => '24:00', '00:00' => '07:00'},
                                                                                    fri: {'18:00' => '24:00', '00:00' => '07:00'},
                                                                                    sat: {'18:00' => '24:00', '00:00' => '07:00'},
                                                                                    sun: {'18:00' => '24:00', '00:00' => '07:00'}}
                                                           config.time_zone = 'Europe/Brussels'})

    flash[:info] = 'De winkel is aangemaakt! Je kan nu producten bewerken en de openingsuren aanpassen.'
    redirect '/admin/winkels'
  end

  get '/admin/winkel/:postcode/:slug/edit/info' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @admin_page = 'shops'
      erb :admin_edit_shop_info
    end
  end

  post '/admin/winkel/:postcode/:slug/edit/info' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false

      param :name, String, required: true, blank: false, format: /^.{1,50}$/
      param :min_price, Float, required: true, blank: false
      param :email, String, required: true, blank: false, format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      param :estimate_delivery_time, Integer, required: true, blank: false
      param :street, String, required: true, blank: false
      param :city, String, required: true, blank: false
      param :new_postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :province, String, required: true, blank: false
    rescue Exception => e
      flash[:warning] = 'De ingevulde gegevens zijn niet mogelijk. Check even alles na en zorg ervoor dat alles in juiste formaat is. (bv: email in juiste vorm, ...)'

      redirect request.fullpath
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @shop.name = params['name']
      @shop.slug = params['name'].slugify
      @shop.min_price = Rack::Utils.escape_html(params['min_price'])
      @shop.email = Rack::Utils.escape_html(params['email'])
      @shop.estimate_delivery_in_minutes = Rack::Utils.escape_html(params['estimate_delivery_time'])
      @shop.address[:address] = params['street']
      @shop.address[:city] = params['city'].downcase
      @shop.address[:postcode] = Rack::Utils.escape_html(params['new_postcode']).to_i
      @shop.address[:province] = params['province']
      @shop.save!

      flash[:info] = 'De wijzigingen zijn successvol toegepast!'
      redirect "/admin/winkel/#{@shop.address[:postcode]}/#{@shop.slug}/edit/info"
    end
  end

  get '/admin/winkel/:postcode/:slug/edit/schedule' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @admin_page = 'shops'
      @hours = @shop.opening_hours.instance_variable_get("@configuration").instance_variable_get("@raw").hours
      erb :admin_edit_shop_schedule
    end
  end

  post '/admin/winkel/:postcode/:slug/edit/schedule' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false

      param :mon_closed, Boolean
      param :mon_start_1, String, required: true, blank: false
      param :mon_end_2, String, required: true, blank: false
      param :tue_closed, Boolean
      param :tue_start_1, String, required: true, blank: false
      param :tue_end_2, String, required: true, blank: false
      param :wed_closed, Boolean
      param :wed_start_1, String, required: true, blank: false
      param :wed_end_2, String, required: true, blank: false
      param :thu_closed, Boolean
      param :thu_start_1, String, required: true, blank: false
      param :thu_end_2, String, required: true, blank: false
      param :fri_closed, Boolean
      param :fri_start_1, String, required: true, blank: false
      param :fri_end_2, String, required: true, blank: false
      param :sat_closed, Boolean
      param :sat_start_1, String, required: true, blank: false
      param :sat_end_2, String, required: true, blank: false
      param :sun_closed, Boolean
      param :sun_start_1, String, required: true, blank: false
      param :sun_end_2, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @mon = params['mon_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['mon_start_1'] => "24:00", "00:00" => params['mon_end_2']}
      @tue = params['tue_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['tue_start_1'] => "24:00", "00:00" => params['tue_end_2']}
      @wed = params['wed_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['wed_start_1'] => "24:00", "00:00" => params['wed_end_2']}
      @thu = params['thu_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['thu_start_1'] => "24:00", "00:00" => params['thu_end_2']}
      @fri = params['fri_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['fri_start_1'] => "24:00", "00:00" => params['fri_end_2']}
      @sat = params['sat_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['sat_start_1'] => "24:00", "00:00" => params['sat_end_2']}
      @sun = params['sun_closed'] ? {'19:00' => '19:00', '07:00' => '07:00'} : {params['sun_start_1'] => "24:00", "00:00" => params['sun_end_2']}

      @shop.opening_hours = Biz::Schedule.new do |config|
        config.hours = {mon: @mon, tue: @tue, wed: @wed, thu: @thu, fri: @fri, sat: @sat, sun: @sun}
        config.time_zone = 'Europe/Brussels'
      end
      @shop.save!

      MongoMapper::Plugins::IdentityMap.clear

      flash[:info] = 'Openingsuren zijn successvol aangepast!'
      redirect '/admin/winkels'
    end
  end

  get '/admin/winkel/:postcode/:slug/edit/products' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @admin_page = 'shops'
      @categories = []
      @shop.products.each do |product|
        @categories << product.category unless @categories.include?(product.category)
      end
      erb :admin_edit_shop_products
    end
  end

  post '/admin/winkel/:postcode/:slug/item/:id/edit' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false

      param :name, String, required: true, blank: false
      param :category, String, required: true, blank: false
      param :price, Float, required: true, blank: false
      param :description, String, required: true, blank: false
      param :min_age, Integer, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      product = Product.find(params['id'])
      category = Category.where(name: params['category']).first

      if product.nil? || category.nil?
        redirect '/admin/winkels'
      else
        product.name = params['name']
        product.slug = params['name'].slugify
        product.price = params['price'].to_f
        product.description = params['description']
        product.min_age = params['min_age'].to_i
        product.category = category
        product.save!

        flash[:info] = 'Product is succesvol aangepast!'
        redirect "/admin/winkel/#{@shop.address['postcode']}/#{@shop.slug}/edit/products"
      end
    end
  end

  post '/admin/winkel/:postcode/:slug/item' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
      param :name, String, required: true, blank: false
      param :price, Float, required: true, blank: false
      param :description, String, required: true, blank: false
      param :min_age, Integer, default: 0
      param :category, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      product = Product.where(name: params['name'], 'shop._id' => @shop.id).first

      if product.nil?
        Product.create(name: params['name'], slug: params['name'].slugify, price: params['price'].to_f, description: params['description'], min_age: params['min_age'].to_i, shop: @shop, category: Category.where(name: params['category']).first)

        flash[:success] = 'Nieuw product is aangemaakt!'
        redirect "/admin/winkel/#{@shop.address['postcode']}/#{@shop.slug}/edit/products"
      else
        flash[:danger] = "Een product met die naam bestaat al in deze winkel!"
        redirect "/admin/winkel/#{@shop.address['postcode']}/#{@shop.slug}/edit/products"
      end
    end
  end

  get '/admin/winkel/:postcode/:slug/delete' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @admin_page = 'shops'
      erb :admin_delete_shop
    end
  end

  post '/admin/winkel/:postcode/:slug/delete' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    unless @shop.nil?
      @shop.products.each {|p| p.destroy}
      @shop.delete
    end

    redirect '/admin/winkels'
  end

  get '/admin/winkel/:postcode/:slug/item' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @admin_page = 'shops'
      @categories = Category.all
      erb :admin_add_item
    end
  end

  post '/admin/winkel/:postcode/:slug/item' do

  end

  get '/admin/winkel/:postcode/:slug/item/:id/delete' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @product = Product.find(params['id'])

      if @product.nil?
        redirect '/admin/winkels'
      else
        erb :admin_delete_item
      end
    end
  end

  post '/admin/winkel/:postcode/:slug/item/:id/delete' do
    protected!

    begin
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :slug, String, required: true, blank: false
    rescue
      redirect '/admin/winkels'
    end

    @shop = Shop.where("address.postcode" => params['postcode'].to_i, slug: Rack::Utils.escape_html(params['slug'])).first

    if @shop.nil?
      redirect '/admin/winkels'
    else
      @product = Product.find(params['id'])

      if @product.nil?
        redirect '/admin/winkels'
      else
        @product.destroy
        flash[:info] = 'Product is succesvol verwijderd!'
        redirect "/admin/winkel/#{@shop.address['postcode']}/#{@shop.slug}/edit/products"
      end
    end
  end

  ## Order Management

  get '/admin/bestellingen' do
    protected!

    @admin_page = 'orders'
    @orders = Order.all
    erb :admin_orders
  end

  get '/admin/bestelling/:id' do
    protected!

    begin
      param :id, String, required: true, blank: false
    rescue
      redirect '/admin/bestellingen'
    end

    @order = Order.find(Rack::Utils.escape_html(params['id']))

    if @order.nil?
      redirect '/admin/bestellingen'
    else
      @products = []
      @order.products.each do |k, v|
        @products << [Product.find(k), v]
      end

      @admin_page = 'orders'

      erb :admin_order
    end
  end

  get '/admin/bestelling/:id/delete' do
    protected!

    begin
      param :id, String, required: true, blank: false
    rescue
      redirect '/admin/bestellingen'
    end

    @order = Order.find(Rack::Utils.escape_html(params['id']))

    if @order.nil?
      redirect '/admin/bestellingen'
    else
      @admin_page = 'orders'

      erb :admin_delete_order
    end
  end

  post '/admin/bestelling/:id/delete' do
    protected!

    begin
      param :id, String, required: true, blank: false
    rescue
      redirect '/admin/bestellingen'
    end

    @order = Order.find(Rack::Utils.escape_html(params['id']))

    if @order.nil?
      redirect '/admin/bestellingen'
    else
      @order.delete
      redirect '/admin/bestellingen'
    end
  end

  ## Category Management

  get '/admin/categorieën' do
    protected!

    @admin_page = 'categories'

    @categories = Category.all
    erb :admin_categories
  end

  post '/admin/categorie' do
    protected!

    begin
      param :name, String, required: true, blank: false, format: /^.{1,50}$/
    rescue Exception => e
      flash[:warning] = 'Lengte van de categorie moet tussen 1-50 karakters zijn!'

      redirect '/admin/categorieën'
    end

    name = Rack::Utils.escape_html(params['name'])

    if Category.where(name: name).all.count >= 1
      flash[:warning] = 'Er bestaat al een categorie met die naam!'

      redirect '/admin/categorieën'
    end

    Category.create(name: name)

    flash[:info] = 'Een nieuwe categorie (' + name + ') is aangemaakt!'
    redirect '/admin/categorieën'
  end

  get '/admin/categorie/:id/delete' do
    protected!

    begin
      param :id, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/categorieën'
    end

    id = Rack::Utils.escape_html(params['id'])

    @category = Category.find(id)

    if @category.nil?
      redirect '/admin/categorieën'
    else
      if @category.products.count >= 1
        flash[:danger] = 'Om een categorie te verwijderen mogen er geen producten deze categorie nog gebruiken!'

        redirect '/admin/categorieën'
      end

      @admin_page = 'categories'

      erb :admin_delete_category
    end
  end

  post '/admin/categorie/:id/delete' do
    protected!

    begin
      param :id, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/categorieën'
    end

    id = Rack::Utils.escape_html(params['id'])

    @category = Category.find(id)

    if @category.nil?
      redirect '/admin/categorieën'
    else
      if @category.products.count >= 1
        flash[:danger] = 'Om een categorie te verwijderen mogen er geen producten deze categorie nog gebruiken!'

        redirect '/admin/categorieën'
      end

      @category.delete

      flash[:info] = 'De categorie is successvol verwijderd.'
      redirect '/admin/categorieën'
    end
  end

  get '/admin/categorie/:id/edit' do
    protected!

    begin
      param :id, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/categorieën'
    end

    @category = Category.find(Rack::Utils.escape_html(params['id']))

    if @category.nil?
      redirect '/admin/categorieën'
    else
      @admin_page = 'categories'
      erb :admin_category
    end
  end

  post '/admin/categorie/:id/edit' do
    protected!

    begin
      param :name, String, required: true, blank: false, format: /^.{1,50}$/
    rescue Exception => e
      flash[:danger] = 'De naam van een categorie moet tussen de 1-50 karakters liggen!'
      redirect request.fullpath
    end

    name = Rack::Utils.escape_html(params['name'])

    @category = Category.find(Rack::Utils.escape_html(params['id']))

    if @category.nil?
      redirect request.fullpath
    else
      if Category.where(name: name).all.count >= 1
        flash[:danger] = 'Er bestaat al een categorie met die naam!'
        redirect request.fullpath
      else
        @category.name = name
        @category.save!

        flash[:info] = 'Naam van de categorie is aangepast.'
        redirect '/admin/categorieën'
      end
    end
  end

  ## Account Management

  get '/admin/gebruikers' do
    protected!

    @accounts = Account.all

    @admin_page = 'accounts'

    erb :admin_accounts
  end

  get '/admin/gebruikers/:phone/disable' do
    protected!

    begin
      param :phone, String, required: true, blank: false
    rescue Exception => e
      flash[:danger] = 'Oops! Er is iets misgegaan.'
      redirect request.fullpath
    end

    account = Account.where(phone: params['phone']).first

    if account.nil?
      flash[:danger] = 'Oops! Er is iets misgegaan.'
      redirect request.fullpath
    end

    account.disabled = !account.disabled?
    account.save!

    flash[:info] = "Het account met telefoon nr. #{account.phone} is nu #{account.disabled? ? "uitgeschakeld" : "ingeschakeld"}!"
    redirect '/admin/gebruikers'
  end

  get '/admin/gebruikers/:phone/delete' do
    protected!

    begin
      param :phone, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/gebruikers'
    end

    @account = Account.where(phone: params['phone']).first

    if @account.nil?
      redirect '/admin/gebruikers'
    else
      @admin_page = 'accounts'
      erb :admin_delete_account
    end
  end

  post '/admin/gebruikers/:phone/delete' do
    protected!

    begin
      param :phone, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/gebruikers'
    end

    @account = Account.where(phone: params['phone']).first

    if @account.nil?
      redirect '/admin/gebruikers'
    else
      @admin_page = 'accounts'
      erb :admin_delete_account
    end

    @account.delete

    flash[:info] = "Het account met telefoon nr. #{@account.phone} is nu verwijderd!"
    redirect '/admin/gebruikers'
  end

  get '/admin/gebruikers/:phone/edit' do
    protected!

    begin
      param :phone, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/gebruikers'
    end

    @account = Account.where(phone: params['phone']).first

    if @account.nil?
      redirect '/admin/gebruikers'
    else
      @admin_page = 'accounts'
      erb :admin_edit_account
    end
  end

  post '/admin/gebruikers/:phone/edit' do
    protected!

    begin
      param :phone, String, required: true, blank: false

      param :form_street, String, required: true, blank: false, format: /^.{3,75}$/
      param :form_housenumber, String, required: true, blank: false, format: /^.{1,10}$/
      param :form_postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :form_phone, String, required: true, blank: false, format: /^.{10}$/

      Float(params['form_phone'])
    rescue Exception => e
      flash[:warning] = <<-WARNING
      Oops! Het ziet er naar uit dat niet alles correct ingevuld is. Alle velden zijn verplicht en zorg ook dat sommige velden in de juiste formaat zijn.
      WARNING

      redirect '/admin/gebruikers'
    end

    @account = Account.where(phone: params['phone']).first

    if @account.nil?
      redirect '/admin/gebruikers'
    end

    if Account.where(:phone => params['form_phone']).count != 0 && Account.where(:phone => params['form_phone']).first.id != @account.id
      flash[:warning] = <<-WARNING
      Oops! Het ziet er naar uit dat er al een account bestaat met die telefoon nr.
      WARNING

      redirect '/admin/gebruikers' and return
    end

    @account.phone = params['form_phone']
    @account.address[:street] = params['form_street']
    @account.address[:housenumber] = params['form_housenumber']
    @account.address[:postcode] = params['form_postcode']

    if params['form_password'].length > 1
      @account.password = BCrypt::Password.create(Rack::Utils.escape_html(params[:form_password]))
    end

    @account.save!

    flash[:info] = "Het account met telefoon nr. #{@account.phone} is succesvol aangepast!"
    redirect '/admin/gebruikers'
  end

  get '/admin/gebruikers/:phone/admin' do
    protected!

    begin
      param :phone, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/gebruikers'
    end

    @account = Account.where(phone: params['phone']).first

    if @account.nil?
      redirect '/admin/gebruikers'
    else
      @admin_page = 'accounts'
      erb :admin_edit_account_admin
    end
  end

  post '/admin/gebruikers/:phone/admin' do
    protected!

    begin
      param :phone, String, required: true, blank: false
    rescue Exception => e
      redirect '/admin/gebruikers'
    end

    @account = Account.where(phone: params['phone']).first

    if @account.nil?
      redirect '/admin/gebruikers'
    end

    @account.admin = !@account.admin
    @account.save!

    flash[:info] = "Het account met telefoon nr. #{@account.phone} zijn admin rechten zijn nu #{@account.admin? ? "toegewezen" : "opgehoffen"}!"
    redirect '/admin/gebruikers'
  end
end