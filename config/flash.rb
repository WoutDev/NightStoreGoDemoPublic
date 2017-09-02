require 'sinatra/flash'

class App < Sinatra::Base
  configure do
    register Sinatra::Flash
  end
end

module Sinatra
  module Flash
    module Style
      def styled_flash(key=:flash)
        '' if flash(key).empty?
        id = (key == :flash ? "flash" : "flash_#{key}")
        close = '<a class="close" data-dismiss="alert" href="#">×</a>'
        messages = flash(key).collect {|message| "  <div class='alert alert-#{message[0]}'>#{close}\n #{message[1]}</div>\n"}
        "<div id='#{id}'>\n" + messages.join + "</div>"
      end
    end
  end
end