require 'openssl'
require 'fileutils'
require 'json'

class Signup
  ## ユーザーフォルダ作成
  def register_user(username, password)
  template_dir = "users/template"
  user_dir = "users/#{username}"
  FileUtils.cp_r(template_dir, user_dir)
  puts "ユーザーフォルダ #{user_dir} を作成しました"

  # 鍵ペア生成
  key = OpenSSL::PKey::RSA.new(2048)
  public_key = key.public_key.to_pem
  encrypted_private_key = key.export(OpenSSL::Cipher.new('AES-256-CBC'), password)

  # 鍵を保存
  File.write("#{user_dir}/public.pem", public_key)
  File.write("#{user_dir}/private.pem", encrypted_private_key)

  # プロフィール保存
  profile = {
    "username" => username,
    "public_key" => public_key,
    "password" => password
  }
  File.write("#{user_dir}/profile.json", JSON.pretty_generate(profile))

  puts "ユーザー #{username} を登録しました！"
  end
end