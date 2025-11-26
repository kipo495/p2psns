require 'webrick'
require_relative 'routes'

port = 8000
server = WEBrick::HTTPServer.new(
  :Port => 8000,
  :AccessLog => []
)

Routes.mount(server)

trap("INT") { server.shutdown }
puts "サーバー起動中: http://localhost:#{port}"
server.start