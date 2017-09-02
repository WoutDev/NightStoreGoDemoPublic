class Product
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :name, String, :required
  key :slug, String, :required
  key :price, Float, :required
  key :description, String
  key :min_age, Integer, default: 0

  belongs_to :category
  belongs_to :shop

  timestamps!
end