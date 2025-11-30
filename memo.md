# メモ

## 階層構造
.
├── test
│   └── GossipTest.md
├── users
│   └── template
│       ├── media
│       ├── pmedia
│       ├── posts
│       └── config.json
├── views
│   ├── form.erb
│   └── home.erb
├── .gitignore
├── data.json
├── gossip.rb
├── memo.md
├── nodes.json
├── routes.rb
├── server.rb
├── signup.rb
└── storage.rb

## 仕様(見た目)

サインイン/サインアップページ
プロフィール(マイページ)
左投稿欄ーーー動的生成(TLなど)ーーー右縦長パネル(ホーム/探索/ブクマ/DM/設定)
右縦長パネルで中央に動的生成、設定ページなど特別なページのみ別でページを用意
「上級者向けUI」などとしていくつかのUIを提供

## 仕様(仕組み)

P2P方式でデータを各ノードが分散保持
ポストなどのデータはCIDで静的に、更新系のものはGossipプロトコルを用いて拡散更新・管理する
Webrickを用いてページをレンダリング、TCPサーバーを平行して起動し更新系データを伝播

ユーザーのデータはusers/中の各ユーザーフォルダに保管
新規登録の際にusers/templateを複製し初期データとする
同時にusername始めとするプロフィールデータを保存

下記二層構造
- 画面描画やユーザー操作 → WEBrick (HTTP)
- ノード間の更新データ伝播 → TCPサーバー (JSON/Gossip)