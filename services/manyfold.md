# Manyfold

3D model library manager for organizing and browsing STL/3MF/OBJ collections.

## Overview

| Property | Value |
|----------|-------|
| Node | SB (sb) |
| LXC | 203 |
| IP | 10.0.0.160 |
| Tailscale IP | 100.117.41.93 |
| Storage | sb-1tb-ssd |
| Status | ✅ Active |

## Access

| Method | URL |
|--------|-----|
| Tailscale HTTPS | https://manyfold.tail-scale.ts.net |

## Architecture

nginx (port 80) sits in front of Puma (port 5000). Tailscale serve proxies external HTTPS traffic to port 80.

```
Tailscale serve (HTTPS) → nginx :80 → Puma :5000
```

nginx config: `/etc/nginx/sites-available/manyfold.conf`

> **Note**: Because Tailscale serve connects to nginx over plain HTTP, nginx sees `$scheme` as `http`. `X-Forwarded-Proto` must be hardcoded to `https` — do not use `$scheme` — so Rails generates correct HTTPS URLs for upload endpoints.

## nginx Configuration

Full working config at `/etc/nginx/sites-available/manyfold.conf`:

```nginx
server {
    listen 80;
    server_name manyfold;
    root /opt/manyfold/app/public;
    client_max_body_size 500M;

    location /cable {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
    }

    location / {
        try_files $uri/index.html $uri @rails;
    }

    location @rails {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        proxy_set_header X-Forwarded-Host $host;
    }
}
```

## Library Storage

| Path | Location | Notes |
|------|----------|-------|
| `/opt/manyfold/app/storage/libraries` | Local on sb-1tb-ssd | NFS mount to DB cold pool deferred |

## Troubleshooting

### Forgot credentials / account locked

Drop into the Manyfold user and open a Rails console:

```bash
su - manyfold
cd /opt/manyfold/app
RAILS_ENV=production bin/rails console
```

List users to find the correct ID:

```ruby
User.all.pluck(:id, :username, :email)
```

Reset password and unlock access:

```ruby
u = User.find(1)
u.password = "new"
u.password_confirmation = "new"
u.save!
u.unlock_access!
```

### Upload failures — file too large

nginx's default `client_max_body_size` is 1MB, which blocks large model uploads. The config above already includes `client_max_body_size 500M;`. If reverting to a fresh config, make sure this is present in the `server` block.

Reload nginx after any config change:

```bash
nginx -s reload
```

### Upload failures — CSP error / http vs https mismatch

**Symptom**: Browser console shows `connect-src 'self'` CSP errors with `http://manyfold.tail-scale.ts.net/upload/...` URLs being blocked.

**Cause**: Tailscale serve connects to nginx over plain HTTP, so nginx sees `$scheme` as `http`. If `X-Forwarded-Proto` is set to `$scheme` (or not set at all), Rails generates `http://` URLs for upload endpoints. The browser blocks these because the page is served over `https://`, violating CSP `connect-src 'self'`.

**Fix**: Hardcode `X-Forwarded-Proto https` in both the `/cable` and `@rails` location blocks. Do **not** use `proxy_set_header X-Forwarded-Proto $scheme` — this will always resolve to `http` in this stack.

After editing, reload nginx:

```bash
nginx -s reload
```

If the browser still shows the old behaviour after the fix, test in a private/incognito window — the regular session may have cached the old `http://` upload URL.

## Related

- [Services Index](_services-index.md)
- [Storage Configuration](../storage.md)
- [Tailscale](tailscale.md)
