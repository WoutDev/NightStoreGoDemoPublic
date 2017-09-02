require 'bcrypt'

class Account
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :phone, String, :required, :unique
  key :password, BCrypt::Password, :required
  key :admin, Boolean, :default => false
  key :address, Hash
  key :disabled, Boolean, :default => false

  timestamps!
end