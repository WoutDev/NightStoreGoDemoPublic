require 'mail'

class App < Sinatra::Base
  configure :development do
    require 'mailcatcher'

    Mail.defaults do
      delivery_method :smtp, address: 'localhost', port: 1025
    end
  end

  configure :production do
    Mail.defaults do
      delivery_method :smtp, address: 'localhost', port: 25, enable_starttls_auto: false
    end
  end
end