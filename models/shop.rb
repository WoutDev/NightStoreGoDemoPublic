require 'biz'

class Shop
  include MongoMapper::Document
  plugin MongoMapper::Plugins::IdentityMap

  key :name, String, :required, :unique
  key :slug, String, :required, :unique
  key :min_price, Float, :required
  key :email, String, :required, :unique
  key :address, Hash, :required, :unique
  key :estimate_delivery_in_minutes, Integer, :required
  key :opening_hours, Biz::Schedule, :required

  has_many :products
  has_many :orders

  timestamps!
end

Biz::Schedule.class_eval do
  def self.to_mongo(value)
    Marshal.dump(value)
  end

  def self.from_mongo(value)
    Marshal.load(value)
  end
end