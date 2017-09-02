class App < Sinatra::Base
  helpers Sinatra::Param
  helpers Rack::Recaptcha::Helpers

  ## Authentication

  get '/login' do
    if authenticated?
      if session[:user].admin?
        redirect '/admin'
      else
        redirect '/'
      end
    end

    erb :login, layout: false
  end

  get '/registreer' do
    if authenticated?
      if session[:user].admin?
        redirect '/admin'
      else
        redirect '/'
      end
    end

    @extra_headers = '<script src="https://www.google.com/recaptcha/api.js" async defer></script>'

    erb :register
  end

  get '/logout' do
    if authenticated?
      session[:user] = nil
    end

    redirect '/login'
  end

  post '/login' do
    if authenticated?
      if session[:user].admin?
        redirect '/admin'
      else
        redirect '/'
      end
    end

    begin
      param :phone, String, required: true, blank: false
      param :password, String, required: true, blank: false
    rescue Exception => e
      flash[:warning] = <<-WARNING
      De combinatie van telefoon nr en wachtwoord is ongeldig.
      WARNING

      redirect '/login'
      return
    end

    phone = Rack::Utils.escape_html(params[:phone])
    password = Rack::Utils.escape_html(params[:password])

    if login(phone, password)
      if session[:user].admin?
        redirect '/admin'
      else
        redirect '/'
      end
    else
      a = Account.where(phone: phone).first

      unless a.nil?
        if BCrypt::Password.new(a.password) == password && a.disabled?
          flash[:warning] = <<-WARNING
          Je account is uitgeschakeld door één van onze beheerders. <a href="/contact">Contacteer ons</a> voor meer info.
          WARNING

          redirect '/login' and return
        end
      end

      flash[:warning] = <<-WARNING
      De combinatie van telefoonnr en wachtwoord is ongeldig.
      WARNING

      redirect '/login'
    end
  end

  post '/registreer' do
    if authenticated?
      if session[:user].admin?
        redirect '/admin'
      else
        redirect '/'
      end
    end

    begin
      param :street, String, required: true, blank: false, format: /^.{3,75}$/
      param :housenumber, String, required: true, blank: false, format: /^.{1,10}$/
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :phone, String, required: true, blank: false, format: /^.{10}$/
      param :password, String, required: true, blank: false, format: /^.{6,100}$/
      param :policies, Boolean, required: true, blank: false, is: true

      Float(params['phone']) # If not a number, an Exception will be thrown

      unless recaptcha_valid?
        raise Sinatra::Param::InvalidParameterError, "Invalid recaptcha"
      end
    rescue Exception => e
      flash[:warning] = <<-WARNING
      Oops! Het ziet er naar uit dat niet alles correct ingevuld is. Alle velden zijn verplicht en zorg ook dat sommige velden in de juiste formaat zijn. Je wachtwoord moet minimum 6 karakters bevatten.
      WARNING

      redirect '/registreer' and return
    end

    street = Rack::Utils.escape_html(params[:street])
    housenumber = Rack::Utils.escape_html(params[:housenumber])
    postcode = Rack::Utils.escape_html(params[:postcode])
    phone = Rack::Utils.escape_html(params[:phone])
    password = Rack::Utils.escape_html(params[:password])

    if Account.where(:phone => phone).count != 0
      flash[:warning] = <<-WARNING
      Oops! Het ziet er naar uit dat er al een account bestaat met die telefoon nr. Indien je je wachtwoord vergeten bent, <a href="/contact">contacteer ons!</a>
      WARNING

      redirect '/registreer' and return
    end

    account = Account.create(phone: phone, password: BCrypt::Password.create(password), address: {street: street, housenumber: housenumber, postcode: postcode.to_i})

    if account.persisted?
      login phone, password

      flash[:success] = <<-SUCCESS
      Je account is succesvol aangemaakt! Je bent nu automatisch ingelogd.
      SUCCESS

      redirect '/' and return
    else
      flash[:warning] = <<-WARNING
      Oops! Er is precies iets misgegaan. Probeer a.u.b. opnieuw!
      WARNING

      redirect '/registreer' and return
    end
  end

  get '/bestellingen' do
    unless authenticated?
      redirect '/' and return
    end

    @orders = Order.where(user_phone: session[:user].phone).all

    erb :orders
  end

  get '/instellingen' do
    unless authenticated?
      redirect '/' and return
    end

    erb :settings
  end

  post '/instellingen' do
    unless authenticated?
        redirect '/'
    end

    begin
      param :street, String, required: true, blank: false, format: /^.{3,75}$/
      param :housenumber, String, required: true, blank: false, format: /^.{1,10}$/
      param :postcode, Integer, required: true, blank: false, min: 1000, max: 10000
      param :phone, String, required: true, blank: false, format: /^.{10}$/
      param :currentpassword, String, required: true, blank: false

      Float(params['phone'])
    rescue Exception => e
      flash[:warning] = <<-WARNING
      Oops! Het ziet er naar uit dat niet alles correct ingevuld is. Alle velden zijn verplicht en zorg ook dat sommige velden in de juiste formaat zijn.
      WARNING

      redirect '/instellingen' and return
    end

    street = Rack::Utils.escape_html(params[:street])
    housenumber = Rack::Utils.escape_html(params[:housenumber])
    postcode = Rack::Utils.escape_html(params[:postcode])
    phone = Rack::Utils.escape_html(params[:phone])
    current_password = Rack::Utils.escape_html(params[:currentpassword])

    if Account.where(:phone => phone).count != 0 && Account.where(:phone => phone).first.id != session[:user].id
      flash[:warning] = <<-WARNING
      Oops! Het ziet er naar uit dat er al een account bestaat met die telefoon nr. Indien je je wachtwoord vergeten bent, <a href="/contact">contacteer ons!</a>
      WARNING

      redirect '/instellingen' and return
    end

    if BCrypt::Password.new(session[:user].password) != current_password
      flash[:warning] = <<-WARNING
      Oops! Je huidige wachtwoord is incorrect.
      WARNING

      redirect '/instellingen' and return
    end

    account = session[:user]

    account.phone = phone
    account.address[:street] = street
    account.address[:housenumber] = housenumber
    account.address[:postcode] = postcode

    if params.keys.include?('password') && params['password'].length > 1
      if params['password'].length < 6
        flash[:warning] = <<-WARNING
        Je nieuw wachtwoord moet minimum 6 karakters bevatten.
        WARNING

        redirect '/instellingen' and return
      end

      account.password = BCrypt::Password.create(Rack::Utils.escape_html(params[:password]))
    end

    account.save!

    flash[:success] = <<-SUCCESS
      Je instellingen zijn aangepast!
    SUCCESS

    redirect '/instellingen'
  end
end