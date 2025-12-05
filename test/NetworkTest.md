# ネットワーク同期テスト手順

## セットアップ

1. **nodes.json を編集** - 既知のノードリストを定義（フルURL推奨）
   ```json
   [
     "http://localhost:8001",
     "http://localhost:8002"
   ]
   ```

2. **複数のノードを起動**
   ```bash
   # ターミナル1: ノード1 (port 8000)
   ruby server.rb
   
   # ターミナル2: ノード2 (port 8001)
   ruby server.rb 8001
   
   # ターミナル3: ノード3 (port 8002)
   ruby server.rb 8002
   ```

## テストシナリオ

### シナリオ1: ローカルタイムラインで投稿確認

1. ノード1 (`http://localhost:8000`) にアクセス
2. ログイン/新規登録してホーム画面へ
3. 投稿を作成 (例: "Hello from Node 1")
4. `/home` で投稿が表示される（ローカル保存確認）

### シナリオ2: グローバルタイムラインでリモート投稿確認

1. ノード1, ノード2 でそれぞれユーザを作成して投稿を複数作成
2. ノード1 で `/global` にアクセス
3. ノード2 からの投稿が表示される（Network.fetch_posts で取得確認）

### シナリオ3: 最新投稿 API（/latest_posts）

1. ブラウザコンソール or curl で確認：
   ```bash
   curl http://localhost:8000/latest_posts
   ```
2. JSON で最新 20 件の投稿を取得できることを確認
3. 複数ノードで投稿を作成して、統合結果を確認

## ロギング・デバッグ

### デバッグモード起動
```bash
ruby server.rb --debug
```

### サーバターミナルに表示されるログ
- `[Routes] /gossip received: ...` - ゴシップ受信
- `[Routes] /gossip post saved: ...` - ゴシップポスト保存
- `Routes:/latest_posts - failed to fetch remote posts: ...` - リモート取得失敗

## トラブルシューティング

- **リモート投稿が見えない**: `nodes.json` が正しいホスト:ポート形式か確認
- **接続失敗**: ファイアウォール設定、ポートが開いているか確認
- **タイムアウト**: Network.fetch_posts の例外処理で warn が出ているか確認
- **重複投稿**: `GET /global` の度に remote posts が追加される（既知） → 今後: ID チェック推奨

## 現行実装状況

- ✅ ローカル投稿保存 (`users/{username}/data/posts.json`)
- ✅ リモート投稿取得 (`Network.fetch_posts`)
- ✅ 最新投稿 API (`/latest_posts`)
- ⚠️ ゴシッププロトコル（`gossip.rb` 定義のみ）
- ⚠️ 無限ループ防止（未実装）

## 今後の改善

- [ ] ゴシッププロトコル完全実装（ノード間ブロードキャスト）
- [ ] 投稿 ID 追加で重複排除
- [ ] メッセージ署名（RSA）で改ざん防止
- [ ] ノード登録/削除の管理エンドポイント
- [ ] 配信失敗の履歴・再試行機構

