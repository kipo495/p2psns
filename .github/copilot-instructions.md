# p2psns - AI Copilot Instructions

## Project Overview

**p2psns** is a peer-to-peer (P2P) distributed social network built with Ruby and WEBrick. Each node runs as a standalone server (port 8000) with local user data and cryptographic key management. The system uses a Gossip protocol for distributed data propagation (implementation in progress).

### Core Architecture

- **HTTP Server**: `server.rb` uses WEBrick to host the web interface
- **Routing Layer**: `routes.rb` handles all endpoint logic (login, signup, home, posts) with cookie-based session management
- **Data Storage**: `storage.rb` manages posts via `data.json` (local, not distributed yet)
- **User Management**: `signup.rb` handles user registration, generates RSA-2048 key pairs (password-encrypted), and clones `users/template/` directory for each new user
- **P2P Gossip**: `gossip.rb` (empty) will implement message propagation across nodes

### Data Structure

Each user gets a dedicated folder (`users/{username}/`):
```
users/{username}/
├── profile.json      # username, public_key
├── public.pem        # RSA public key (PEM)
├── private.pem       # RSA private key (AES-256-CBC encrypted with password)
├── config.json       # (empty, placeholder for user config)
├── media/            # User-generated media
├── pmedia/           # Processed media
└── posts/            # User's posts
```

Posts stored centrally in `data.json`: `[{user, message, time}, ...]`

## Development Patterns

### Key Workflow Differences

1. **Session Management**: Uses WEBrick cookies (`user` cookie stores username). Routes check `req.cookies.find { |c| c.name == "user" }` for authentication.

2. **ERB Template Reuse**: Both login and signup share `views/form.erb` with dynamic variables (title, action, submit_label, button, button_label). Pass these via `binding` in ERB context.

3. **File-Based Persistence**: 
   - Posts: `Storage.load_posts` and `Storage.save_posts(posts)` handle JSON I/O
   - User profiles: Direct JSON read/write at `users/{username}/profile.json`
   - Passwords: Stored in `profile.json` (not yet hashed - security concern for future)

4. **User Registration Flow**:
   - `FileUtils.cp_r("users/template", "users/#{username}")` clones template directory
   - Generate RSA-2048 keypair with password-protected private key
   - Save keys and profile metadata
   - Redirect to `/home` with user cookie

### Adding New Endpoints

- Add `server.mount_proc '/route'` block in `routes.rb`
- Check authentication via `req.cookies.find { |c| c.name == "user" }`
- Use `ERB.new(File.read("views/template.erb")).result(binding)` for HTML rendering
- Return redirects with `res.set_redirect(WEBrick::HTTPStatus::Found, "/path")`

### Working with Cryptography

- RSA keys use OpenSSL: `OpenSSL::PKey::RSA.new(2048)`
- Private keys encrypted with AES-256-CBC: `key.export(OpenSSL::Cipher.new('AES-256-CBC'), password)`
- Signing/verification framework exists in test file but not yet integrated
- See `test/nodeSimulate.rb` for RSA key generation and Gossip algorithm reference

## Critical Implementation Notes

1. **No Distributed Data Yet**: Posts stored centrally in `data.json`. Gossip protocol will broadcast updates when implemented.

2. **Password Use**: Passwords are used only to encrypt/decrypt RSA private keys (AES-256-CBC cipher). Not stored in profile.json. Private key decryption requires correct password.

3. **Session Timeout**: No expiration on cookies. Future: add timestamp validation.

4. **Template Variable Binding**: ERB templates expect variables in scope before `binding` is called. Always set title, action, submit_label, button, button_label before rendering.

5. **No Heavy Frameworks**: Project intentionally minimalist—uses only WEBrick and stdlib (OpenSSL, FileUtils, JSON). Keep implementations lightweight without external dependencies.

6. **Cryptography Pattern**: Private keys encrypted with AES-256-CBC using user password as cipher key. Load with: `OpenSSL::PKey::RSA.new(encrypted_key_data, password)`. See `signup.rb` line ~16 for encryption example.

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

- `routes.rb` requires: `storage.rb`, `signup.rb`, WEBrick, ERB
- `signup.rb` requires: OpenSSL, FileUtils, JSON
- `server.rb` requires: `routes.rb`, WEBrick
- `views/form.erb`, `views/home.erb`: expect variables via ERB binding
