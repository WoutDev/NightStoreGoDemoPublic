require 'rubygems'
require 'bundler/setup'
require 'sinatra'

require 'slugify'

class App < Sinatra::Base
  use Rack::Session::Pool, key: 'rack.session', path: '/', expire_after: 2592000
  use Rack::Protection
end

require_relative './config/init'  # Initialize configuration files
require_relative './helpers/init' # Initialize helpers
require_relative './routes/init'  # Initialize routes
require_relative './models/init'  # Initialize models

require_relative './util/tokens'  # Token utility

configure :production do
  # Insert basic user account if not exists, admin is the only exception to accounts (other accounts use phone)
  unless Account.where(phone: 'admin').count == 1
    Account.create(phone: 'admin', password: BCrypt::Password.create('< hard coded password which definitely should be changed after creation >'), address: {street: '', housenumber: '', postcode: 0}, admin: true)
  end
end

# Reset & insert basic data when developing
configure :development do
  Shop.destroy_all
  Product.destroy_all
  Category.destroy_all
  Account.destroy_all
  Order.destroy_all

  hours = Biz::Schedule.new do |config|
    config.hours = {
        mon: {'18:00' => '24:00', '00:00' => '07:00'},
        tue: {'18:00' => '24:00', '00:00' => '07:00'},
        wed: {'16:00' => '24:00', '00:00' => '07:00'},
        thu: {'12:00' => '24:00', '00:00' => '07:00'},
        fri: {'18:00' => '24:00', '00:00' => '07:00'},
        sat: {'18:00' => '24:00', '00:00' => '07:00'},
        sun: {'18:00' => '24:00', '00:00' => '07:00'}
    }

    config.time_zone = 'Europe/Brussels'
  end

  shop_one = Shop.create(name: "T's Nachtwinkel", slug: "T's Nachtwinkel".slugify, email: 'some1@email.com', opening_hours: hours, min_price: 10.00, estimate_delivery_in_minutes: 60, address: {province: 'Antwerpen', city: 'antwerpen', postcode: 2000, address: 'Nachtwinkelbaan 4'})
  # shop_two = Shop.create(name: "Andere Nachtwinkel", slug: "Andere Nachtwinkel".slugify, email: 'some2@email.com', opening_hours: hours, min_price: 12.00, estimate_delivery_in_minutes: 60, address: {province: 'Antwerpen', city: 'westmalle', postcode: 2390, address: 'Anderebaan 6'})
  # shop_three = Shop.create(name: "Centrum nachtwinkel", slug: "Centrum nachtwinkel".slugify, email: 'some3@email.com', opening_hours: hours, min_price: 9.00, estimate_delivery_in_minutes: 70, address: {province: 'Antwerpen', city: 'antwerpen', postcode: 2000, address: 'Centrumbaan 259'})
  shop_four = Shop.create(name: "Competatieve nachtwinkel", slug: "Competatieve nachtwinkel".slugify, email: 'some4@email.com', opening_hours: hours, min_price: 8.60, estimate_delivery_in_minutes: 50, address: {province: 'Antwerpen', city: 'antwerpen', postcode: 2000, address: 'Centrumbaan 259'})

  admin = Account.create(phone: 'admin', password: BCrypt::Password.create('foo'), address: {street: '', housenumber: '', postcode: 0}, admin: true)
  wout = Account.create(phone: 'wout', password: BCrypt::Password.create('foo'), address: {street: '', housenumber: '', postcode: 0})

  drinks = Category.create(name: 'Drinks')
  snacks = Category.create(name: 'Snacks')
  alcohol_cigarettes = Category.create(name: 'Alcohol & Cigarettes')

  # Drinks
  cola = 'Coca Cola 1L'
  cola_slug = cola.slugify

  cola_one = Product.create(name: cola, slug: cola_slug, price: 4.00, description: '1L coca cola fles', category: drinks, shop: shop_one)
  # cola_two = Product.create(name: cola, slug: cola_slug, price: 4.20, description: '1L coca cola fles', category: drinks, shop: shop_two)
  # cola_three = Product.create(name: cola, slug: cola_slug, price: 4.00, description: '1L coca cola fles', category: drinks, shop: shop_three)
  cola_four = Product.create(name: cola, slug: cola_slug, price: 3.90, description: '1L coca cola fles', category: drinks, shop: shop_four)

  ice_tea = 'Ice Tea 2L'
  ice_tea_slug = ice_tea.slugify

  ice_tea_one = Product.create(name: ice_tea, slug: ice_tea_slug, price: 3.60, description: 'Ice Tea 1L', category: drinks, shop: shop_one)
  # ice_tea_two = Product.create(name: ice_tea, slug: ice_tea_slug, price: 3.60, description: 'Ice Tea 1L', category: drinks, shop: shop_two)
  # ice_tea_three = Product.create(name: ice_tea, slug: ice_tea_slug, price: 4.00, description: 'Ice Tea 1L', category: drinks, shop: shop_three)
  ice_tea_four = Product.create(name: ice_tea, slug: ice_tea_slug, price: 3.55, description: 'Ice Tea 1L', category: drinks, shop: shop_four)

  red_bull = 'Red Bull 25cl'
  red_bull_slug = red_bull.slugify

  red_bull_one = Product.create(name: red_bull, slug: red_bull_slug, price: 2.60, description: 'Red Bull 25cl blik', category: drinks, shop: shop_one)
  # red_bull_two = Product.create(name: red_bull, slug: red_bull_slug, price: 3.00, description: 'Red Bull 25cl blik', category: drinks, shop: shop_two)
  # red_bull_three = Product.create(name: red_bull, slug: red_bull_slug, price: 2.70, description: 'Red Bull 25cl blik', category: drinks, shop: shop_three)
  red_bull_four = Product.create(name: red_bull, slug: red_bull_slug, price: 2.40, description: 'Red Bull 25cl blik', category: drinks, shop: shop_four)

  fristi = 'Fristi Fruit 1L'
  fristi_slug = fristi.slugify

  fristi_one = Product.create(name: fristi, slug: fristi_slug, price: 9.99, description: 'Fristi Fruit rood 1L blik', category: drinks, shop: shop_one)
  # fristi_two = Product.create(name: fristi, slug: fristi_slug, price: 9.99, description: 'Fristi Fruit rood 1L blik', category: drinks, shop: shop_two)
  # fristi_three = Product.create(name: fristi, slug: fristi_slug, price: 9.99, description: 'Fristi Fruit rood 1L blik', category: drinks, shop: shop_three)
  fristi_four = Product.create(name: fristi, slug: fristi_slug, price: 9.99, description: 'Fristi Fruit rood 1L blik', category: drinks, shop: shop_four)

  rodeo = 'Rodeo 25cl'
  rodeo_slug = rodeo.slugify

  rodeo_one = Product.create(name: rodeo, slug: rodeo_slug, price: 1.20, description: 'Rodeo energy drink 25cl', category: drinks, shop: shop_one)
  # rodeo_two = Product.create(name: rodeo, slug: rodeo_slug, price: 1.40, description: 'Rodeo energy drink 25cl', category: drinks, shop: shop_two)
  # rodeo_three = Product.create(name: rodeo, slug: rodeo_slug, price: 1.30, description: 'Rodeo energy drink 25cl', category: drinks, shop: shop_three)
  rodeo_four = Product.create(name: rodeo, slug: rodeo_slug, price: 1.10, description: 'Rodeo energy drink 25cl', category: drinks, shop: shop_four)

  monster_rehab = 'Monster Rehab 500ml'
  monster_rehab_slug = monster_rehab.slugify

  monster_rehab_one = Product.create(name: monster_rehab, slug: monster_rehab_slug, price: 2.40, description: 'Monster Rehab 500ml', category: drinks, shop: shop_one)
  # monster_rehab_two = Product.create(name: monster_rehab, slug: monster_rehab_slug, price: 3.00, description: 'Monster Rehab 500ml', category: drinks, shop: shop_two)
  # monster_rehab_three = Product.create(name: monster_rehab, slug: monster_rehab_slug, price: 2.40, description: 'Monster Rehab 500ml', category: drinks, shop: shop_three)
  monster_rehab_four = Product.create(name: monster_rehab, slug: monster_rehab_slug, price: 2.20, description: 'Monster Rehab 500ml', category: drinks, shop: shop_four)

  # Snacks
  doritos = 'Doritos Sweet Chilli Pepper 200g'
  doritos_slug = doritos.slugify

  doritos_one = Product.create(name: doritos, slug: doritos_slug, price: 5.00, description: '200g Doritos Sweet Chilli Pepper chips', category: snacks, shop: shop_one)
  # doritos_two = Product.create(name: doritos, slug: doritos_slug, price: 5.10, description: '200g Doritos Sweet Chilli Pepper chips', category: snacks, shop: shop_two)
  # doritos_three = Product.create(name: doritos, slug: doritos_slug, price: 5.20, description: '200g Doritos Sweet Chilli Pepper chips', category: snacks, shop: shop_three)
  doritos_four = Product.create(name: doritos, slug: doritos_slug, price: 4.90, description: '200g Doritos Sweet Chilli Pepper chips', category: snacks, shop: shop_four)

  lays_chips = 'Lay\'s Ketchup 250g'
  lays_chips_slug = lays_chips.slugify

  lays_chips_one = Product.create(name: lays_chips, slug: lays_chips_slug, price: 4.60, description: '250g Lay\'s Ketchup chips', category: snacks, shop: shop_one)
  # lays_chips_two = Product.create(name: lays_chips, slug: lays_chips_slug, price: 4.70, description: '250g Lay\'s Ketchup chips', category: snacks, shop: shop_two)
  # lays_chips_three = Product.create(name: lays_chips, slug: lays_chips_slug, price: 4.60, description: '250g Lay\'s Ketchup chips', category: snacks, shop: shop_three)
  lays_chips_four = Product.create(name: lays_chips, slug: lays_chips_slug, price: 4.50, description: '250g Lay\'s Ketchup chips', category: snacks, shop: shop_four)

  # Alcohol & cigarettes
  cara_pils = 'Cara Everyday 33cl'
  cara_pils_slug = cara_pils.slugify

  cara_pils_one = Product.create(name: cara_pils, slug: cara_pils_slug, price: 1.00, description: 'Cara Pils Everyday 4.4% blik 33cl', category: alcohol_cigarettes, min_age: 16, shop: shop_one)
  # cara_pils_two = Product.create(name: cara_pils, slug: cara_pils_slug, price: 1.10, description: 'Cara Pils Everyday 4.4% blik 33cl', category: alcohol_cigarettes, min_age: 16, shop: shop_two)
  # cara_pils_three = Product.create(name: cara_pils, slug: cara_pils_slug, price: 1.20, description: 'Cara Pils Everyday 4.4% blik 33cl', category: alcohol_cigarettes, min_age: 16, shop: shop_three)
  cara_pils_four = Product.create(name: cara_pils, slug: cara_pils_slug, price: 0.90, description: 'Cara Pils Everyday 4.4% blik 33cl', category: alcohol_cigarettes, min_age: 16, shop: shop_four)

  marlboro_cigarettes = 'Marlboro Cigarettes'
  marlboro_cigarettes_slug = marlboro_cigarettes.slugify

  marlboro_cigarettes_one = Product.create(name: marlboro_cigarettes, slug: marlboro_cigarettes_slug, price: 6.30, description: 'Marlboro Gold 19+1 Cigarettes.', category: alcohol_cigarettes, min_age: 18, shop: shop_one)
  # marlboro_cigarettes_two = Product.create(name: marlboro_cigarettes, slug: marlboro_cigarettes_slug, price: 6.40, description: 'Marlboro Gold 19+1 Cigarettes.', category: alcohol_cigarettes, min_age: 16, shop: shop_two)
  # marlboro_cigarettes_three = Product.create(name: marlboro_cigarettes, slug: marlboro_cigarettes_slug, price: 6.30, description: 'Marlboro Gold 19+1 Cigarettes.', category: alcohol_cigarettes, min_age: 16, shop: shop_three)
  marlboro_cigarettes_four = Product.create(name: marlboro_cigarettes, slug: marlboro_cigarettes_slug, price: 6.10, description: 'Marlboro Gold 19+1 Cigarettes.', category: alcohol_cigarettes, min_age: 16, shop: shop_four)

  # order_one = Order.create(phone: '04xx xxx xxx', address: {street: 'Koekoeksdreef', housenumber: 1, postcode: 2980}, comments: 'blablabla abc 23', ip: '127.0.0.1', products: {cara_pils_two.id.to_s => {name: cara_pils_two.name, quantity: 6}}, total: 55)
end
