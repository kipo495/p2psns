require 'webrick'
require_relative 'storage'
require_relative 'signup'
require 'erb'


class Routes
  def self.mount(server)
    posts = Storage.load_posts

    server.mount_proc '/' do |req, res|
      if req.request_method == 'POST'
        user = req.query["user"]
        password = req.query["password"]
        profile_file = "users/#{user}/profile.json"

        if File.exist?(profile_file)
          data = JSON.parse(File.read(profile_file))
          if data["username"] == user && data["password"] == password
            res.cookies << WEBrick::Cookie.new("user", user)
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
        action = "/login"
        submit_label = "ログイン"
        button = "/signup"
        button_label = "新規登録"
        res.body = ERB.new(File.read("views/form.erb")).result(binding)
      end
    end

    server.mount_proc '/signup' do |req, res|
      if req.request_method == 'POST'
        user = req.query["user"]
        password = req.query["password"]

        if user && password
          Signup.new.register_user(user, password)
          res.cookies << WEBrick::Cookie.new("user", user)
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
      user_cookie = req.cookies.find { |c| c.name == "user" }
      if user_cookie
        user = user_cookie.value
        res['Content-Type'] = 'text/html; charset=utf-8'
        res.body = ERB.new(File.read("views/home.erb")).result(binding)
      else
        res.set_redirect(WEBrick::HTTPStatus::Found, "/login")
      end
    end

    server.mount_proc '/post' do |req, res|
      posts << { "user" => req.query["user"], "message" => req.query["message"], "time" => Time.now.to_s }
      Storage.save_posts(posts)
      res.set_redirect(WEBrick::HTTPStatus::Found, "/home")
    end
end
end