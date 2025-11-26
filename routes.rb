require 'webrick'
require_relative 'storage'
require 'erb'

class Routes
  def self.mount(server)
    posts = Storage.load_posts

    server.mount_proc '/' do |req, res|
      res['Content-Type'] = 'text/html; charset=utf-8'
      res.body = ERB.new(File.read("views/index.erb")).result(binding)
    end

    server.mount_proc '/post' do |req, res|
      posts << { "user" => req.query["user"], "message" => req.query["message"], "time" => Time.now.to_s }
      Storage.save_posts(posts)
      res.set_redirect(WEBrick::HTTPStatus::Found, "/")
    end
  end
end