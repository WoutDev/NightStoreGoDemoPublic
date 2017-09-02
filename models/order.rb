class Order
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :address, Hash, :required
  key :phone, String, :required
  key :comments, String, :required
  key :ip, String, :required
  key :products, Hash, :required
  key :total, Float, :required
  key :user_phone, String

  belongs_to :shop

  timestamps!
end