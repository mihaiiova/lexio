# Deployment configuration for static hosting

# All routes serve index.html (SPA fallback)
# Flutter web uses hash-based routing by default, so this handles direct URL access

# --- Cloudflare Pages ---
# Place this file as-is in the root. Cloudflare Pages auto-detects _redirects.
# /_redirects
/*    /index.html   200

# --- Netlify ---
# Rename to _redirects or use netlify.toml:
# [[redirects]]
#   from = "/*"
#   to = "/index.html"
#   status = 200

# --- Vercel ---
# Create vercel.json:
# {
#   "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
# }
