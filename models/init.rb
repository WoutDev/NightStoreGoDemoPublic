require 'activemodel-serializers-xml'
require 'mongo_mapper/document'

require_relative 'shop'
require_relative 'category'
require_relative 'product'
require_relative 'order'
require_relative 'account'

Account.ensure_index(:phone, unique: true)
Product.ensure_index(:name)
Shop.ensure_index(:name)
Order.ensure_index(:user_phone)