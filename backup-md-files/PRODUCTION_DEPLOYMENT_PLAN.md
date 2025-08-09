# RapidTriageME Production Deployment Plan

## 🎯 Objective
Deploy RapidTriageME HTTP MCP to production with full browser automation capabilities.

## 📋 Current Status
- ✅ Cloudflare Worker deployed at https://rapidtriage.me
- ✅ Authentication configured
- ✅ MCP protocol implemented
- ❌ Browser backend not deployed
- ❌ Production infrastructure not set up

## 🚀 Priority 1: Critical Path to Production (Week 1)

### 1. Deploy Browser Automation Backend
**Option A: Google Cloud Run (Recommended)**
```bash
# 1. Containerize the backend
cd rapidtriage-server
docker build -t gcr.io/rapidtriage/backend:latest .

# 2. Push to Google Container Registry
docker push gcr.io/rapidtriage/backend:latest

# 3. Deploy to Cloud Run
gcloud run deploy rapidtriage-backend \
  --image gcr.io/rapidtriage/backend:latest \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --memory 2Gi \
  --cpu 2 \
  --timeout 60 \
  --max-instances 10
```

**Option B: AWS ECS/Fargate**
```bash
# 1. Push to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin
docker tag rapidtriage-backend:latest [ECR_URI]/rapidtriage-backend:latest
docker push [ECR_URI]/rapidtriage-backend:latest

# 2. Deploy with ECS
aws ecs create-service \
  --cluster rapidtriage \
  --service-name backend \
  --task-definition rapidtriage-backend \
  --desired-count 2 \
  --launch-type FARGATE
```

**Option C: Railway/Render (Quick Deploy)**
```bash
# Railway
railway login
railway init
railway up

# Render
# Use render.yaml in repo
render deploy
```

### 2. Configure Production Backend URL
```bash
# Update Cloudflare Worker secret
wrangler secret put BACKEND_URL --env production
# Enter: https://backend.rapidtriage.me or Cloud Run URL
```

### 3. Set Up SSL/TLS
```yaml
# If using custom domain
# cloudflare-ssl-config.yaml
ssl:
  mode: "full_strict"
  certificate: "edge_certificates"
  minimum_version: "TLS_1_2"
```

## 🛠️ Priority 2: Production Readiness (Week 2)

### 4. Database & Storage Setup

**Option A: Cloudflare D1 (Recommended for KV)**
```sql
-- Create sessions database
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  data TEXT,
  expires_at DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE audit_logs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id TEXT,
  action TEXT,
  metadata TEXT,
  timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

**Option B: PostgreSQL (Supabase/Neon)**
```javascript
// supabase-client.js
const { createClient } = require('@supabase/supabase-js');
const supabase = createClient(SUPABASE_URL, SUPABASE_KEY);
```

### 5. Monitoring & Observability

**Cloudflare Analytics**
```javascript
// Add to Worker
ctx.waitUntil(
  env.ANALYTICS.writeDataPoint({
    blobs: [request.method, url.pathname],
    doubles: [Date.now() - startTime],
    indexes: [request.headers.get('CF-Connecting-IP')]
  })
);
```

**Sentry Integration**
```javascript
// sentry-config.js
import * as Sentry from "@sentry/cloudflare";

Sentry.init({
  dsn: "YOUR_SENTRY_DSN",
  environment: "production",
  tracesSampleRate: 0.1,
});
```

**Grafana/Datadog**
```yaml
# datadog-agent.yaml
logs:
  - type: http
    port: 10518
    service: rapidtriage
    source: cloudflare-worker
```

### 6. Rate Limiting & Security

**Cloudflare Rate Limiting Rules**
```javascript
// wrangler.toml
[[rate_limiting]]
threshold = 100
period = 60
action = "challenge"

[[firewall_rules]]
expression = "(ip.geoip.country in {\"CN\" \"RU\" \"KP\"})"
action = "block"
```

**DDoS Protection**
```javascript
// Add to Worker
const rateLimiter = new RateLimiter({
  tokensPerInterval: 100,
  interval: "minute",
  fireImmediately: true
});

if (!rateLimiter.tryRemoveTokens(1)) {
  return new Response("Rate limited", { status: 429 });
}
```

## 📊 Priority 3: Scale & Optimize (Week 3)

### 7. CI/CD Pipeline

**GitHub Actions**
```yaml
# .github/workflows/deploy.yml
name: Deploy to Production

on:
  push:
    branches: [main]

jobs:
  deploy-worker:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cloudflare/wrangler-action@v3
        with:
          apiToken: ${{ secrets.CF_API_TOKEN }}
          environment: production
          
  deploy-backend:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Deploy to Cloud Run
        run: |
          gcloud run deploy rapidtriage-backend \
            --source . \
            --region us-central1
```

### 8. Load Balancing & Auto-scaling

**Cloud Run Auto-scaling**
```yaml
# service.yaml
apiVersion: serving.knative.dev/v1
kind: Service
spec:
  template:
    metadata:
      annotations:
        autoscaling.knative.dev/minScale: "1"
        autoscaling.knative.dev/maxScale: "100"
        autoscaling.knative.dev/target: "80"
```

**Cloudflare Load Balancer**
```javascript
// Configure multiple backend origins
const backends = [
  'https://backend1.rapidtriage.me',
  'https://backend2.rapidtriage.me',
  'https://backend3.rapidtriage.me'
];

const backend = backends[Math.floor(Math.random() * backends.length)];
```

### 9. Caching Strategy

**Cloudflare Cache Rules**
```javascript
// Cache responses
const cacheKey = new Request(url, request);
const cache = caches.default;

let response = await cache.match(cacheKey);
if (!response) {
  response = await fetch(backend);
  ctx.waitUntil(cache.put(cacheKey, response.clone()));
}
```

**Redis for Session Cache**
```javascript
// redis-client.js
const redis = new Redis({
  url: process.env.REDIS_URL
});

await redis.set(`session:${id}`, JSON.stringify(data), 'EX', 3600);
```

## 🔒 Priority 4: Security & Compliance (Week 4)

### 10. Security Hardening

**Security Headers**
```javascript
const securityHeaders = {
  'Content-Security-Policy': "default-src 'self'",
  'X-Frame-Options': 'DENY',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'strict-origin-when-cross-origin',
  'Permissions-Policy': 'geolocation=(), microphone=(), camera=()'
};
```

**API Key Rotation**
```bash
# Rotate keys monthly
#!/bin/bash
NEW_KEY=$(openssl rand -base64 32)
wrangler secret put API_KEY --env production
echo "New API key: $NEW_KEY"
```

**Penetration Testing**
```bash
# Use OWASP ZAP
docker run -t owasp/zap2docker-stable zap-baseline.py \
  -t https://rapidtriage.me
```

## 📝 Immediate Action Items

### This Week (Priority 1)
1. **Deploy Backend** to Cloud Run/ECS/Railway
2. **Update Backend URL** in Cloudflare Worker
3. **Test End-to-End** functionality

### Next Week (Priority 2)
4. **Set up monitoring** with Sentry/Datadog
5. **Configure database** for sessions
6. **Implement rate limiting**

### Week 3 (Priority 3)
7. **Set up CI/CD** pipeline
8. **Configure auto-scaling**
9. **Implement caching**

### Week 4 (Priority 4)
10. **Security audit**
11. **Load testing**
12. **Documentation**

## 🎯 Success Metrics

- ✅ Backend deployed and accessible
- ✅ All MCP tools functional
- ✅ < 500ms average response time
- ✅ 99.9% uptime SLA
- ✅ Zero security vulnerabilities
- ✅ Automated deployment pipeline
- ✅ Real-time monitoring dashboard

## 💰 Estimated Costs

| Service | Cost/Month | Notes |
|---------|-----------|-------|
| Cloudflare Worker | $5 | 10M requests included |
| Cloud Run | $50 | 2 instances, 2GB RAM |
| Database | $25 | D1 or Postgres |
| Monitoring | $100 | Datadog/Sentry |
| SSL Certificate | $0 | Cloudflare included |
| **Total** | **~$180/month** | Can start with free tiers |

## 🚦 Quick Deploy Commands

```bash
# 1. Deploy backend to Cloud Run (fastest)
gcloud run deploy rapidtriage-backend \
  --source rapidtriage-server \
  --region us-central1 \
  --allow-unauthenticated

# 2. Get the backend URL
BACKEND_URL=$(gcloud run services describe rapidtriage-backend \
  --region us-central1 \
  --format 'value(status.url)')

# 3. Update Cloudflare Worker
echo $BACKEND_URL | wrangler secret put BACKEND_URL --env production

# 4. Test production
curl https://rapidtriage.me/health
```

## 📊 Production Checklist

- [ ] Backend deployed to cloud
- [ ] SSL/TLS configured
- [ ] Database provisioned
- [ ] Monitoring enabled
- [ ] Rate limiting active
- [ ] CI/CD pipeline setup
- [ ] Auto-scaling configured
- [ ] Caching implemented
- [ ] Security audit passed
- [ ] Load testing completed
- [ ] Documentation updated
- [ ] Backup strategy in place

## 🆘 Support & Resources

- [Google Cloud Run Docs](https://cloud.google.com/run/docs)
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers)
- [Docker Documentation](https://docs.docker.com)
- [Puppeteer Troubleshooting](https://pptr.dev/troubleshooting)

---

*Ready to deploy? Start with Priority 1 items and work through the checklist!*