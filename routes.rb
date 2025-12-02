require 'webrick'
require 'erb'
require 'json'
require 'time'
require 'openssl'
require 'net/http'
require_relative 'storage'
require_relative 'signup'
require_relative 'network'

class Routes
  def self.mount(server)

    server.mount_proc '/' do |req, res|
      if req.request_method == 'POST'
        username = req.query["username"]
        password = req.query["password"]
        profile_file = "users/#{username}/profile.json"

        if File.exist?(profile_file)
          data = JSON.parse(File.read(profile_file))
          if Signup.new.authenticate_user(username, password)
            res.cookies << WEBrick::Cookie.new("username", username)
            res.set_redirect(WEBrick::HTTPStatus::Found, "/home")
          else
            res.body = "ユーザー名またはパスワードが違います"
          end
        else
          res.body = "ユーザーが存在しません"
        end
      else
        # ログインフォーム表示
        res['Content-Type'] = 'text/html; charset=utf-8'
        title = "ログイン"
        action = "/"
        submit_label = "ログイン"
        button = "/signup"
        button_label = "新規登録"
        res.body = ERB.new(File.read("views/form.erb")).result(binding)
      end
    end

    server.mount_proc '/signup' do |req, res|
      if req.request_method == 'POST'
        username = req.query["username"]
        password = req.query["password"]

        if username && password
          Signup.new.register_user(username, password)
          res.cookies << WEBrick::Cookie.new("username", username)
          res.set_redirect(WEBrick::HTTPStatus::Found, "/home")
        else
          res.body = "ユーザー名とパスワードを入力してください"
        end
      else
        # 新規登録フォーム表示
        res['Content-Type'] = 'text/html; charset=utf-8'
        title = "新規登録"
        action = "/signup"
        submit_label = "登録"
        button = "/"
        button_label = "ログイン"
        res.body = ERB.new(File.read("views/form.erb")).result(binding)
      end
    end

    server.mount_proc '/home' do |req, res|
      username_cookie = req.cookies.find { |c| c.name == "username" }
      if username_cookie
        username = username_cookie.value
        res['Content-Type'] = 'text/html; charset=utf-8'
        # ローカル + リモートを統合してビューに渡す
        begin
          posts = (Storage.load_posts + Network.fetch_posts)
        rescue => e
          warn "Routes:/home - failed to fetch network posts: #{e.message}"
          posts = Storage.load_posts
        end
        posts = posts.sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse
        res.body = ERB.new(File.read("views/home.erb")).result(binding)
      else
        res.set_redirect(WEBrick::HTTPStatus::Found, "/")
      end
    end

    server.mount_proc '/post' do |req, res|
      event = { "username" => req.query["username"], "message" => req.query["message"], "time" => Time.now.to_s }
      # ユーザ別ファイルへ保存
      Storage.save_post(event)
      res.set_redirect(WEBrick::HTTPStatus::Found, "/home")
    end

    server.mount_proc '/latest_posts' do |req, res|
      if req.request_method == 'GET'
        res['Content-Type'] = 'application/json'
        local = Storage.load_posts
        begin
          remote = Network.fetch_posts
        rescue => e
          warn "Routes:/latest_posts - failed to fetch remote posts: #{e.message}"
          remote = []
        end
        combined = (local + remote).sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse.take(20)
        res.body = JSON.generate(combined)
      else
        res.status = 405
        res.body = 'method not allowed'
      end
    end
  end
end