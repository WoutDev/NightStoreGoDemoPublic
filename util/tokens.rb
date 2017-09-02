class Tokens
  @@tokens = {}

  def self.gen_token
    o = [('a'..'z'), ('A'..'Z'), (0...9)].map(&:to_a).flatten

    token = (0...20).map { o[rand(o.length)] }.join

    @@tokens.store(token, false)

    token
  end

  def self.check_token(token)
    @@tokens.include?(token) && !@@tokens[token]
  end

  def self.remove_token(token)
    @@tokens.delete(token)
  end
end