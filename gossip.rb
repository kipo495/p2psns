require 'net/http'
require 'uri'
require 'json'

module Gossip
  ## ノードリストを読み込む
  def self.load_nodes(path = 'nodes.json')
    return [] unless File.exist?(path)
    JSON.parse(File.read(path))
  rescue
    []
  end

  ## JSONイベントを全ノードに送信
  def self.broadcast(event, nodes = nil, async: true)
    nodes ||= load_nodes
    return if nodes.empty?

    # 自ノードをノード一覧から除外する（環境変数またはデフォルトポートを参照）
    my_port = (ENV['PORT'] || ENV['WEB_PORT'] || ARGV.find { |a| a =~ /^\d+$/ } || '8000').to_s
    my_host_port = "localhost:#{my_port}"
    nodes_to_send = nodes.map(&:to_s).reject { |n| n == my_host_port }
    return if nodes_to_send.empty?

    payload = event.is_a?(String) ? event : event.to_json

    puts "[Gossip] broadcasting to: #{nodes_to_send.inspect}"

    nodes_to_send.each do |node|
      host_port = node.to_s
      uri = URI.parse("http://#{host_port}/gossip")
      ## 非同期POST
      if async
        Thread.new { post_json(uri, payload) }
      else
        post_json(uri, payload)
      end
    end
  end

  def self.post_json(uri, payload, retries = 2)
    attempt = 0
    begin
      req = Net::HTTP::Post.new(uri.request_uri, {'Content-Type' => 'application/json'})
      req.body = payload
      puts "[Gossip] sending to #{uri}"
      Net::HTTP.start(uri.host, uri.port, open_timeout: 3, read_timeout: 5) do |http|
        res = http.request(req)
        puts "[Gossip] delivered to #{uri} status=#{res.code}"
        res
      end
    rescue => e
      attempt += 1
      if attempt <= retries
        warn "[Gossip] delivery failed to #{uri}: #{e.message}, retrying... (#{attempt}/#{retries})"
        sleep(0.5 * attempt)
        retry
      else
        warn "[Gossip] delivery failed to #{uri} after #{retries} retries: #{e.message}"
        nil
      end
    end
  end
end