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

  nodes = load_nodes

  def self.fetch_posts
    posts = []
    ## 各ノードのエンドポイントにGETしポストを取得
    nodes.each do |node|
      begin
        uri = URI.join(node, "/latest_posts")
        res = Net::HTTP.get_response(uri)
        if res.code == "200"
          data = JSON.parse(res.body)
          posts += data
        end
      rescue => e
        warn "Failed to fetch from #{node}: #{e.message}"
      end
    end
    posts.sort_by { |p| p["time"] }.reverse
    return posts
  end
end

class Timeline
  def self.local
    posts = Storage.load_posts
  end
  def self.global
    posts = Network.fetch_posts
  end
end