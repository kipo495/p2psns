require 'webrick'
require_relative 'routes'
require_relative 'gossip'

# コマンドオプション
port = (ARGV[0] || 8000).to_i
debug = ARGV.include?('--debug')

webrick_log_level = debug ? WEBrick::Log::DEBUG : WEBrick::Log::WARN
webrick_logger = WEBrick::Log.new($stdout, webrick_log_level)
access_log = debug ? [[ $stdout, "%h %l %u %t \"%r\" %>s %b" ]] : []

server = WEBrick::HTTPServer.new(
  :Port => port,
  :AccessLog => access_log,
  :Logger => webrick_logger
)

Routes.mount(server)

trap("INT") do
  puts "[DEBUG] received INT, shutting down" if debug
  if defined?(gossip) && gossip && gossip.respond_to?(:stop)
    puts "[DEBUG] stopping gossip" if debug
    begin
      gossip.stop
    rescue => e
      puts "[DEBUG] error stopping gossip: #{e.class} #{e.message}" if debug
    end
  end
  server.shutdown
end

puts "サーバー起動中: http://localhost:#{port} #{'(debug)' if debug}"
server.start