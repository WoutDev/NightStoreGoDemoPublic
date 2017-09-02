def protected!
  unless authenticated? && session[:user].admin?
    raise Sinatra::NotFound
  end
end

def authenticated?
  !session[:user].nil?
end

def login(phone, password)
  account = nil

  Account.all.each do |a|
    if a.phone == phone && BCrypt::Password.new(a.password) == password && !a.disabled?
      account = a
    end
  end

  unless account.nil?
    session[:user] = account
  end

  !account.nil?
end
