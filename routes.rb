require 'webrick'
require 'erb'
require 'json'
require 'time'
require 'openssl'
require 'net/http'
require 'securerandom'
require_relative 'storage'
require_relative 'signup'
require_relative 'network'

# グローバルセッションストア（簡易実装）
$sessions ||= {}

class Routes
  def self.mount(server)

    server.mount_proc '/' do |req, res|
      if req.request_method == 'POST'
        username = req.query["username"]
        password = req.query["password"]
        profile_file = "users/#{username}/data/profile.json"

        if File.exist?(profile_file)
          data = JSON.parse(File.read(profile_file))
          if Signup.authenticate_user(username, password)
            # セッション発行
            session_id = SecureRandom.hex(32)
            $sessions[session_id] = data
            cookie = WEBrick::Cookie.new("session_id", session_id)
            cookie.secure = false
            cookie.path = "/"
            cookie.expires = Time.now + 86400
            res.cookies << cookie
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

    server.mount_proc '/logout' do |req, res|
      session_cookie = req.cookies.find { |c| c.name == "session_id" }
      if session_cookie
        session_cookie.expires = Time.now - 3600
        $sessions.delete(session_cookie.value)
      end
      res.set_redirect(WEBrick::HTTPStatus::Found, "/")
    end

    server.mount_proc '/signup' do |req, res|
      if req.request_method == 'POST'
        username = req.query["username"]
        password = req.query["password"]

        if username && password
          user = File.exist?("users/#{username}/data/profile.json")
          if !user
            Signup.register_user(username, password)
            user_data = JSON.parse(File.read("users/#{username}/data/profile.json"))
            session_id = SecureRandom.hex(32) # ランダムなセッションID生成
            $sessions[session_id] = user_data # セッションとユーザ情報を紐づけ
            ## セッション-クッキーを生成
            cookie = WEBrick::Cookie.new("session_id", session_id)
            cookie.secure = false
            cookie.path = "/"
            cookie.expires = Time.now + 86400
            res.cookies << cookie
            res.set_redirect(WEBrick::HTTPStatus::Found, "/home")
          else
            res.body = "ユーザーが既に存在します"
          end
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
      session_cookie = req.cookies.find { |c| c.name == "session_id" }
      sess = $sessions[session_cookie.value]
      if session_cookie && sess
        res['Content-Type'] = 'text/html; charset=utf-8'
        username = sess["username"]
        config = JSON.parse(File.read("./users/#{username}/data/config.json"))
        theme = config['theme']
        posts = Storage.load_posts
        posts = posts.sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse
        res.body = ERB.new(File.read("views/home.erb")).result(binding)
      else
        res.set_redirect(WEBrick::HTTPStatus::Found, "/")
      end
    end

    server.mount_proc '/global' do |req, res|
      session_cookie = req.cookies.find { |c| c.name == "session_id" }
      sess = $sessions[session_cookie.value]
      if session_cookie && sess
        res['Content-Type'] = 'text/html; charset=utf-8'
        username = sess["username"]
        config = JSON.parse(File.read("./users/#{username}/data/config.json"))
        theme = config['theme']
        posts = Network.fetch_posts
        posts = posts.sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse
        res.body = ERB.new(File.read("views/home.erb")).result(binding)
      else
        res.set_redirect(WEBrick::HTTPStatus::Found, "/")
      end
    end

    server.mount_proc '/post' do |req, res|
      session_cookie = req.cookies.find { |c| c.name == "session_id" }
      sess = $sessions[session_cookie.value]
      if session_cookie && sess
        username = sess["username"]
      end
      event = { "username" => username, "message" => req.query["message"], "time" => Time.now.to_s }
      # ユーザ別ファイルへ保存
      Storage.save_post(event)
      referer = req.header["referer"]&.first
      if referer
        res.set_redirect(WEBrick::HTTPStatus::Found, referer)
      else
        res.set_redirect(WEBrick::HTTPStatus::Found, "/home")
      end
    end

    server.mount_proc '/latest_posts' do |req, res|
      if req.request_method == 'GET'
        res['Content-Type'] = 'application/json'
        local = Storage.load_posts
        local = local.sort_by { |p| Time.parse(p["time"]) rescue p["time"] }.reverse.take(20)
        res.body = JSON.generate(local)
      else
        res.status = 405
        res.body = 'method not allowed'
      end
    end

    server.mount_proc '/config' do |req, res|
      session_cookie = req.cookies.find { |c| c.name == "session_id" }
      sess = $sessions[session_cookie.value]
      if session_cookie && sess
        username = sess["username"]
        if req.request_method == 'POST'
          # フォームデータから changes オブジェクトを構築
          changes = {
            "theme" => req.query["theme"],
            "layout" => req.query["layout"],
            "fontSize" => req.query["fontSize"],
            "showMedia" => req.query["showMedia"],
            "notifications" => {
              "enable" => req.query["notifications_enable"],
              "enableOnDesktop" => req.query["notifications_enableOnDesktop"]
            },
            "visibility" => req.query["visibility"]
          }
          Storage.save_config(username, changes)
          res.set_redirect(WEBrick::HTTPStatus::Found, "/config")
        else
          # GET リクエスト: 設定ページを表示
          res['Content-Type'] = 'text/html; charset=utf-8'
          config = Storage.load_config(username)
          res.body = ERB.new(File.read("views/config.erb")).result(binding)
        end
      else
        res.set_redirect(WEBrick::HTTPStatus::Found, "/")
      end
    end
  end
end