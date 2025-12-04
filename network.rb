require 'net/http'
require 'uri'
require 'json'

module Network
  def self.load_nodes(path = 'nodes.json')
    return [] unless File.exist?(path)
    JSON.parse(File.read(path))
  rescue
    []
  end

  def self.fetch_posts
    nodes = load_nodes
    posts = []
    ## 各ノードのエンドポイントにGETしポストを取得
    nodes.each do |node|
      begin
        uri = URI.join("http://#{node}" "/latest_posts")
        res = Net::HTTP.get_response(uri)
        if res.code == "200"
          data = JSON.parse(res.body)
          posts += data
          puts posts.value
        end
      rescue Errno::ECONNREFUSED, SocketError => e
        puts "ノード #{uri} に接続できませんでした: #{e.message}"
      rescue JSON::ParserError => e
        puts "ノード #{uri} のレスポンスがJSONとして不正: #{e.message}"
      rescue StandardError => e
        puts "ノード #{uri} で予期せぬエラー: #{e.class} - #{e.message}"
      end

    end
    posts.sort_by { |p| p["time"] }.reverse
    return posts
  end
end