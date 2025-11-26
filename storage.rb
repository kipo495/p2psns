require 'json'

class Storage
  DATA_FILE = "data.json"

  def self.load_posts
    File.exist?(DATA_FILE) ? JSON.parse(File.read(DATA_FILE)) : []
  end

  def self.save_posts(posts)
    File.write(DATA_FILE, JSON.pretty_generate(posts))
  end
end