# config.ru
require 'lotus'
require_relative 'ticktock'

class TickTockServer < Lotus::Application
  configure do
    routes do
      get '/', to: ->(env) {
        [200, {}, [TickTock.new.uninvoiced_income_projection.to_s]]
      }
    end
  end
end

run TickTockServer.new