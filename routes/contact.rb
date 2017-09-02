class App < Sinatra::Base
  helpers Sinatra::Param
  helpers Rack::Recaptcha::Helpers

  get '/contact' do
    include_general_params
    erb :contact
  end

  after '/contact' do
    if request.request_method == "GET"
      session[:contact] = {}
    end
  end

  post '/contact' do
    include_general_params

    subject_titles = []
    @subjects.values.each { |hash| subject_titles << hash[:text]}

    session[:contact] = {}

    begin
      param :name, String, required: true, blank: false
      param :email, String, required: true, format: /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
      param :subject, String, required: true, in: subject_titles
      param :message, String, required: true, format: /^.{25,500}$/

      unless recaptcha_valid?
        raise Sinatra::Param::InvalidParameterError, "Invalid recaptcha"
      end
    rescue Exception => e
      flash[:warning] = <<-WARNING
      <strong>Oops!</strong> Er is iets misgelopen tijdens het versturen. Let op de volgende criteria: <br />
      - Alle velden zijn verplicht <br />
      - Email moet in een juist formaat <br />
      - Bericht tussen de 25 en 500 karakters <br />
      WARNING

      redirect '/contact'
    ensure
      @name = session[:contact][:name] = Rack::Utils.escape_html(params[:name])
      @email = session[:contact][:email] = Rack::Utils.escape_html(params[:email])
      @subject = session[:contact][:subject] = Rack::Utils.escape_html(params[:subject])
      @message = session[:contact][:message] = Rack::Utils.escape_html(params[:message])
    end

    Thread.new do
      to = ''

      @subjects.each do |k,v|
        if v[:text] == params['subject']
          to = v[:email]
        end
      end

      body = "Naam: #{@name} \n"
      body += "Email: #{@email}\n"
      body += "IP: #{request.ip}\n"
      body += "Bericht: \n\n#{@message}\n\n\n"
      body += "=== Einde Bericht ===\n"
      body += "Gelieven NIET te reageren op deze email. Het bericht was verstuurd via onze contactpagina en daarom is het het beste om rechtreeks te reageren via deze email: #{@email}"

      unless to == ''
        send_mail(to, 'contact@email.com', 'NightStoreGo! Contact: ' + @subject, body)
      end
    end

    flash[:info] = 'Je bericht is succesvol verstuurd! We hopen je bericht zo snel mogelijk te kunnen beantwoorden.'

    session[:contact].clear

    redirect '/contact'
  end

  private
    def include_general_params
      @subjects ||= {technical: {text: 'Technisch', email: 'some@email.com'}}
      @extra_headers = '<script src="https://www.google.com/recaptcha/api.js" async defer></script>'
      @page = 'contact'
    end
end