require 'mongo'
require 'mongo_mapper'

class App < Sinatra::Base
  configure :development do
    MongoMapper.connection = Mongo::MongoClient.new('localhost', 27017)
    MongoMapper.database = 'test'
  end

  configure :production do
    MongoMapper.connection = Mongo::MongoClient.new('localhost', 27017)
    MongoMapper.database = 'prod'
  end
end