class App < Sinatra::Base
  error Sinatra::NotFound do
    erb :not_found
  end

  error 500..599 do
    erb :server_error
  end
end