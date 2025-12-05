require 'json'
require 'fileutils'
require 'time'

class Storage
  # ポストをロード
  def self.load_posts
    posts = []
    Dir.glob("./users/*/data/posts.json").each do |path|
      next if path.include?("template") # テンプレートは除外
      data = JSON.parse(File.read(path))
      posts.concat(data) if data.is_a?(Array)
    end
      posts.sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse
      return posts
  end

  # ポストをセーブ
  def self.save_post(post)
    username = post['username']
    return false unless username
    user_dir = "./users/#{username}"
    return false unless Dir.exist?(user_dir)
    file = "#{user_dir}/data/posts.json"
    posts = File.exist?(file) ? JSON.parse(File.read(file)) : []
    posts << post
    File.write(file, JSON.pretty_generate(posts))
    true
  end

  #配列やハッシュもセーブ
  def self.save_posts(posts)
    if posts.is_a?(Array)
      posts.each { |p| save_post(p) }
    elsif posts.is_a?(Hash)
      save_post(posts)
    end
  end

  ## 設定をロード
  def self.load_config(username = "kipo")
    config_dir = "./users/#{username}/data/config.json"
    config = JSON.parse(File.read(config_dir))
    return config
  end

  ## 設定を保存
  def self.save_config(username = "kipo", changes)
    config_dir = "./users/#{username}/data/config.json"
    FileUtils.mkdir_p(File.dirname(config_dir))
    # 既存設定をロードしてマージ
    existing_config = File.exist?(config_dir) ? JSON.parse(File.read(config_dir)) : {}
    updated_config = existing_config.merge(changes)
    File.write(config_dir, JSON.pretty_generate(updated_config))
  end
end