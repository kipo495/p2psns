require 'json'
require 'fileutils'
require 'time'

class Storage
  ## 自分のポストを読み込む
  def self.load_posts
    posts = []
    Dir.glob("./users/*/posts.json").each do |path|
      next if path.include?("template") # テンプレートは除外
      data = JSON.parse(File.read(path))
      posts.concat(data) if data.is_a?(Array)
    end
      posts.sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse
      return posts
  end

  # 単一ポストをユーザごとのファイルに保存する(戻り値T/F)
  def self.save_post(post)
    username = post['username']
    return false unless username
    user_dir = "./users/#{username}"
    return false unless Dir.exist?(user_dir)
    file = "#{user_dir}/posts.json"
    posts = File.exist?(file) ? JSON.parse(File.read(file)) : []
    posts << post
    File.write(file, JSON.pretty_generate(posts))
    true
  end

  #配列やハッシュを受け取る
  def self.save_posts(posts)
    if posts.is_a?(Array)
      posts.each { |p| save_post(p) }
    elsif posts.is_a?(Hash)
      save_post(posts)
    end
  end
end