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

### Upload failures via Tailscale URL

nginx's default `client_max_body_size` is 1MB, which blocks large model uploads. Edit the nginx config:

```bash
nano /etc/nginx/sites-available/manyfold.conf
```

Add inside the `server` block:

```nginx
client_max_body_size 500M;
```

Reload nginx without downtime:

```bash
nginx -s reload
```

## Related

- [Services Index](_services-index.md)
- [Storage Configuration](../storage.md)
- [Tailscale](tailscale.md)
