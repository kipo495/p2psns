## 鍵ペア生成と保存

require 'securerandom'
require 'openssl'

# RSA方式で鍵ペアを生成
key = OpenSSL::PKey::RSA.new(2048)

private_key = key.to_pem
public_key = key.public_key.to_pem

password = "my_secret_password"

# AES-256-CBCでkey(private_key)暗号化してPEM形式に変換
encrypted_private_key = key.export(OpenSSL::Cipher.new('AES-256-CBC'), password)

# ファイルに保存
File.write("private.pem", encrypted_private_key)
File.write("public.pem", public_key)
puts "鍵ペアを生成し、保存しました"

# 復号
encrypted_key_data = File.read("private.pem")
restored_key = OpenSSL::PKey::RSA.new(encrypted_key_data, password)

puts restored_key.private?  # => true （秘密鍵として復元できた）


## 署名と検証のテスト

# message = "Hello, P2P SNS!"
# signature = key.sign(OpenSSL::Digest::SHA256.new, message)
# puts "署名: #{signature.unpack1('H*')}"

# valid = key.public_key.verify(OpenSSL::Digest::SHA256.new, signature, message)
# puts "署名は正しい？ #{valid}"


## ノードシミュレーション

# ノードを表すクラス
class Node
  attr_reader :id, :messages

  def initialize
    @id = SecureRandom.hex(2)   # ノードID
    @messages = []              # 知っているメッセージ
  end

  # 新しいメッセージを受け取る
  def receive(message)
    unless @messages.include?(message)
      @messages << message
      puts "Node #{@id} learned: #{message}"
    end
  end

  # ランダムな相手にメッセージを伝える
  def gossip(peers)
    return if @messages.empty?
    peer = peers.sample
    message = @messages.sample
    peer.receive(message)
  end
end

# # ノードを複数作成
# nodes = Array.new(5) { Node.new }

# # 最初のノードがメッセージを知っている
# nodes.first.receive("RubyでP2P SNSを作ろう！")

# # 10ラウンド繰り返す
# 10.times do |round|
#   puts "--- Round #{round} ---"
#   nodes.each do |node|
#     node.gossip(nodes - [node])
#   end
# end

# # 最終的に全員がメッセージを知っているか確認
# nodes.each do |node|
#   puts "Node #{node.id} knows: #{node.messages}"
# end