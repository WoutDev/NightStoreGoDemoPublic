require 'rack/recaptcha'

class App < Sinatra::Base
  configure :development do
    use Rack::Recaptcha, public_key: 'dev_public_key', private_key: 'dev_private_key'
  end

  configure :production do
    use Rack::Recaptcha, public_key: 'prod_public_key', private_key: 'prod_private_key'
  end
end