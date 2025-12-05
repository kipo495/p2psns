# p2psns - AI Copilot Instructions

## Project Overview

**p2psns** is a peer-to-peer (P2P) distributed social network built with Ruby and WEBrick. Each node runs as a standalone server (port 8000) with local user data and cryptographic key management. The system uses a Gossip protocol for distributed data propagation (implementation in progress).

### Core Architecture

- **HTTP Server**: `server.rb` uses WEBrick to host the web interface (port 8000)
- **Routing Layer**: `routes.rb` handles endpoints (login, signup, home, post, config, latest_posts) with session-based auth
- **Data Storage**: `storage.rb` manages per-user posts (`users/{username}/data/posts.json`)
- **User Management**: `signup.rb` handles registration, RSA-2048 key generation, user folder setup
- **P2P Network**: `network.rb` fetches posts from remote nodes via `/latest_posts`
- **Theming**: `public/css/theme.css` supports Bootstrap 5 + custom dark/default themes, font sizes, layouts
- **Views**: ERB templates in `views/` (form.erb, home.erb, config.erb)

### Data Structure

Each user gets a dedicated folder (`users/{username}/data/`):
```
users/{username}/
├── data/
│   ├── profile.json      # username, public_key, password (plain text)
│   ├── config.json       # theme, layout, fontSize, showMedia, notifications, visibility
│   ├── posts.json        # [{username, message, time}, ...]
│   └── followers.json    # (placeholder, not yet used)
├── public.pem            # RSA public key (PEM)
├── private.pem           # RSA private key (AES-256-CBC encrypted)
├── media/                # User-generated media (placeholder)
└── pmedia/               # Processed media (placeholder)
```

Posts stored per-user: `users/{username}/data/posts.json` contains array of post objects.

## Development Patterns

### Key Workflow Differences

1. **Session Management**: Uses WEBrick cookies (`session_id` cookie stores hashed session ID). Routes check `req.cookies.find { |c| c.name == "session_id" }` for authentication. Session data stored in global `$sessions` hash.

2. **ERB Template Reuse**: Both login and signup share `views/form.erb` with dynamic variables (title, action, submit_label, button, button_label). Pass these via `binding` in ERB context.

3. **File-Based Persistence**: 
   - Posts: `Storage.load_posts` aggregates all user posts; `Storage.save_post(post)` saves per-user
   - User profiles: Direct JSON read/write at `users/{username}/data/profile.json`
   - User config: `Storage.load_config(username)` / `Storage.save_config(username, changes)` handle config.json

4. **User Registration Flow**:
   - `FileUtils.cp_r("users/template", "users/#{username}")` clones template directory
   - Generate RSA-2048 keypair with password-protected private key
   - Save keys and profile metadata to `users/{username}/data/profile.json`
   - Generate session ID, store in `$sessions`, set secure cookie
   - Redirect to `/home` with session_id cookie

5. **Theme System**: 
   - User config contains `theme` ("default" or "dark"), `fontSize` ("small"/"medium"/"large"), `layout` ("default"/"advanced")
   - Bootstrap 5 CDN + custom CSS (`public/css/theme.css`) applies styles via body class
   - All pages load config on each request and apply theme classes

### Adding New Endpoints

- Add `server.mount_proc '/route'` block in `routes.rb`
- Check authentication via session cookie: `session_cookie = req.cookies.find { |c| c.name == "session_id" }` and `sess = $sessions[session_cookie.value]`
- For GET: Use `ERB.new(File.read("views/template.erb")).result(binding)` for HTML rendering
- For POST: Parse `req.query` for form data
- Return redirects with `res.set_redirect(WEBrick::HTTPStatus::Found, "/path")`
- Set content type: `res['Content-Type'] = 'text/html; charset=utf-8'`

### Working with Cryptography

- RSA keys use OpenSSL: `OpenSSL::PKey::RSA.new(2048)`
- Private keys encrypted with AES-256-CBC: `key.export(OpenSSL::Cipher.new('AES-256-CBC'), password)`
- Signing/verification framework exists in test file but not yet integrated
- See `test/nodeSimulate.rb` for RSA key generation and Gossip algorithm reference

## Critical Implementation Notes

1. **Per-User Post Storage**: Posts stored separately in `users/{username}/data/posts.json`. Gossip protocol will broadcast updates when implemented.

2. **Password Use**: Passwords are used only to encrypt/decrypt RSA private keys (AES-256-CBC cipher). Not hashed or stored in profile.json. Private key decryption requires correct password.

3. **Session Timeout**: No expiration on cookies. Future: add timestamp validation.

4. **Template Variable Binding**: ERB templates expect variables in scope before `binding` is called. Always set config, username, posts, title, action, submit_label, button, button_label (as needed) before rendering.

5. **No Heavy Frameworks**: Project intentionally minimalist—uses only WEBrick and stdlib (OpenSSL, FileUtils, JSON). Keep implementations lightweight without external dependencies.

6. **Cryptography Pattern**: Private keys encrypted with AES-256-CBC using user password as cipher key. Load with: `OpenSSL::PKey::RSA.new(encrypted_key_data, password)`. See `signup.rb` for encryption example.

7. **Static Files**: CSS and other static assets served via `/public` mount in `server.rb`.

## Running the Project

```bash
ruby server.rb  # Starts WEBrick on port 8000
# Navigate to http://localhost:8000
```

No tests runner configured—manual browser testing or use `test/nodeSimulate.rb` patterns for unit tests when needed.

## Dependencies

**No external gems required.** Project uses only Ruby stdlib:

- **WEBrick** - HTTP server (stdlib)
- **OpenSSL** - RSA key generation, AES-256-CBC encryption (stdlib)
- **FileUtils** - Directory operations (`cp_r`, `mkdir_p`) (stdlib)
- **JSON** - Data serialization (stdlib)
- **ERB** - HTML template rendering (stdlib)

Run with: `ruby server.rb` on Ruby 2.5+

## File Dependencies

- `routes.rb` requires: `storage.rb`, `signup.rb`, `network.rb`, WEBrick, ERB
- `signup.rb` requires: OpenSSL, FileUtils, JSON
- `server.rb` requires: `routes.rb`, `network.rb`, WEBrick
- `views/form.erb`, `views/home.erb`, `views/config.erb`: expect variables via ERB binding
