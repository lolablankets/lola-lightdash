# Migrate Lightdash from nip.io to lightdash.lolablankets.com

## Current State

- Lightdash is running at: `https://lightdash.89-167-44-60.nip.io`
- Server IP: `89.167.44.60`
- Deployment: Docker Compose (`docker-compose.yml`) with PostgreSQL, MinIO, headless browser
- Lightdash listens on port `8080` inside the container
- nip.io is a wildcard DNS service — `*.89-167-44-60.nip.io` resolves to `89.167.44.60` automatically, no DNS config needed
- There is likely a reverse proxy (nginx, Caddy, etc.) on the server handling HTTPS termination — check the server

## Target State

- Lightdash accessible at: `https://lightdash.lolablankets.com`
- Valid SSL certificate via Let's Encrypt
- Same server, same IP (`89.167.44.60`)

---

## Prerequisites — What You Need

- [x] **DNS access** for `lolablankets.com` — managed via Shopify DNS panel
- [ ] **SSH access** to the server at `89.167.44.60` (Hetzner VPS — ask teammate for credentials)
- [ ] Know which reverse proxy is running (nginx? Caddy? Traefik? direct?)

## Step 1: Create DNS Record ✅ DONE

A record added via Shopify DNS panel:

| Type | Name        | Value           |
|------|-------------|-----------------|
| A    | `lightdash` | `89.167.44.60`  |

**Verify** (after DNS propagates, usually 1-5 min):
```bash
dig lightdash.lolablankets.com
# or
nslookup lightdash.lolablankets.com
```

## Step 2: SSH into the Server and Identify the Setup ⬅️ NEXT (needs teammate)

> **Note**: This is a shared Hetzner VPS — there are likely other services running on it besides Lightdash. Be careful not to disrupt them.

```bash
ssh <user>@89.167.44.60   # get credentials from teammate
```

Figure out what's running:
```bash
# What containers are running?
docker ps

# Is there a reverse proxy?
docker ps | grep -E 'nginx|caddy|traefik'

# Or is it installed directly on the host?
which nginx caddy traefik

# Check what's listening on port 443/80
ss -tlnp | grep -E ':80|:443'

# Find the .env file for the Lightdash compose setup
find / -name ".env" -path "*/lightdash*" 2>/dev/null
# or check common locations
ls /opt/lightdash/.env /root/.env ~/lightdash/.env 2>/dev/null
```

## Step 3: Update the Reverse Proxy

### If nginx:

Find the config (likely `/etc/nginx/sites-enabled/` or `/etc/nginx/conf.d/`):
```bash
grep -r "nip.io" /etc/nginx/
```

Update `server_name`:
```nginx
server_name lightdash.lolablankets.com;
```

If using Certbot for SSL:
```bash
sudo certbot --nginx -d lightdash.lolablankets.com
sudo nginx -t && sudo systemctl reload nginx
```

### If Caddy:

Find the Caddyfile:
```bash
find / -name "Caddyfile" 2>/dev/null
```

Update it:
```
lightdash.lolablankets.com {
    reverse_proxy localhost:8080
}
```

Caddy handles SSL automatically — just reload:
```bash
caddy reload --config /path/to/Caddyfile
```

### If Traefik (Docker labels):

Update the Docker Compose labels on the Lightdash service to use the new domain.

### If no reverse proxy (Lightdash directly on port 443):

You'll need to set one up. Caddy is the easiest:
```bash
# Install Caddy
sudo apt install -y caddy

# Create Caddyfile
cat > /etc/caddy/Caddyfile << 'EOF'
lightdash.lolablankets.com {
    reverse_proxy localhost:8080
}
EOF

sudo systemctl enable --now caddy
```

## Step 4: Update Lightdash Environment

Find and update the `.env` file used by Docker Compose:

```bash
# Change SITE_URL from the nip.io address to the new domain
SITE_URL=https://lightdash.lolablankets.com

# Enable these if not already set (required for HTTPS behind a proxy)
TRUST_PROXY=true
SECURE_COOKIES=true
```

Then restart Lightdash:
```bash
cd /path/to/lightdash
docker compose down
docker compose up -d
```

## Step 5: Verify

- [ ] `https://lightdash.lolablankets.com` loads the Lightdash UI
- [ ] SSL certificate is valid (check browser padlock)
- [ ] Login works (cookies require `SECURE_COOKIES=true` + HTTPS)
- [ ] Scheduled deliveries / email links use the correct URL (driven by `SITE_URL`)
- [ ] OAuth callbacks work if Google Auth is configured (update Google OAuth redirect URI to new domain)

## Step 6: Clean Up (Optional)

- [ ] Remove old nip.io reverse proxy config if desired
- [ ] If using Google OAuth, update the authorized redirect URI in Google Cloud Console from `https://lightdash.89-167-44-60.nip.io/api/v1/oauth/redirect/google` to `https://lightdash.lolablankets.com/api/v1/oauth/redirect/google`
- [ ] If Slack integration is configured, update the Slack app redirect URLs

---

## Quick Summary

| Step | What | Where |
|------|------|-------|
| 1 | Add DNS `A` record | Your DNS provider |
| 2 | Identify reverse proxy | SSH into server |
| 3 | Update proxy `server_name` + SSL cert | Server reverse proxy config |
| 4 | Set `SITE_URL`, `TRUST_PROXY`, `SECURE_COOKIES` in `.env` | Server, Lightdash .env |
| 5 | Restart Lightdash | `docker compose up -d` |
| 6 | Update OAuth redirect URIs if applicable | Google Cloud Console, Slack, etc. |
