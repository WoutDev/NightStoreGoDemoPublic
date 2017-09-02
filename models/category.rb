class Category
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :name, String, :required, :unique

  has_many :products

  timestamps!
end