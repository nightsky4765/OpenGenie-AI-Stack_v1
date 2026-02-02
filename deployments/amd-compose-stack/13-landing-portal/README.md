# Phase 13: Landing Portal

## Overview
Professional landing page for TigerAI Open-AI-Stack, providing a modern web interface for service discovery, status monitoring, and system overview.

## Architecture
- **Service**: Nginx (Alpine)
- **Port**: 80 (HTTP), 443 (HTTPS)
- **Network**: ai_stack_net
- **Type**: Stateless web server

## Features
✨ **Modern UI Design**
- Glassmorphism effects
- Gradient animations
- Smooth transitions
- Responsive layout

📊 **Service Status Monitoring**
- Real-time health checks
- Service discovery
- System metrics display

🚀 **Quick Navigation**
- Direct links to all services
- Architecture overview
- Documentation access

🔒 **Security**
- Security headers (X-Frame-Options, CSP, etc.)
- API proxy to Phase 12 Gateway
- No direct service exposure

## Technology Stack
- **Frontend**: HTML5 + CSS3 + Vanilla JavaScript
- **Web Server**: Nginx Alpine
- **API Integration**: Phase 12 Commercial Gateway

## Deployment

### Prerequisites
- Docker and Docker Compose installed
- `ai_stack_net` network created
- Phase 12 Gateway running (for API calls)

### Quick Start
```bash
# Deploy the landing portal
./deploy.sh

# Access the portal
# Open browser: http://localhost:80
```

### Configuration
Edit `.env` file to customize:
```bash
LANDING_PORT=80              # HTTP port
LANDING_PORT_SSL=443         # HTTPS port (requires SSL cert)
GATEWAY_API_URL=http://system-api-bridge:8000
```

## File Structure
```
13-landing-portal/
├── docker-compose.yaml      # Container orchestration
├── .env                     # Environment configuration
├── nginx.conf               # Nginx configuration
├── deploy.sh                # Deployment script
├── html/
│   ├── index.html          # Main landing page
│   ├── styles.css          # Premium CSS styles
│   └── app.js              # Application logic
└── README.md               # This file
```

## API Integration
The landing page calls Phase 12 Gateway API for:
- `/health` - System health status
- Service availability checks
- License validation

API calls are proxied through Nginx at `/api/*` to avoid CORS issues.

## Customization

### Adding New Services
Edit `html/app.js` and add to `CONFIG.SERVICES`:
```javascript
{
    id: 'phase-XX',
    name: 'Service Name',
    description: 'Service description',
    port: 'XXXX',
    icon: '🎯',
    phase: XX
}
```

### Styling
- Edit `html/styles.css` for visual customization
- Modify CSS variables in `:root` for theme changes
- Update gradient colors, spacing, typography

### Content
- Edit `html/index.html` for content changes
- Update hero section, service descriptions
- Modify architecture diagram

## Monitoring
```bash
# View logs
docker logs -f landing-portal

# Check container status
docker ps --filter "name=landing-portal"

# Restart service
docker restart landing-portal
```

## Troubleshooting

### Port 80 Already in Use
```bash
# Change port in .env
LANDING_PORT=8080

# Redeploy
./deploy.sh
```

### API Calls Failing
- Verify Phase 12 Gateway is running
- Check `GATEWAY_API_URL` in `.env`
- Ensure containers are on same network

### Static Files Not Loading
```bash
# Check file permissions
chmod -R 755 html/

# Verify nginx.conf syntax
docker exec landing-portal nginx -t

# Reload nginx
docker exec landing-portal nginx -s reload
```

## Security Considerations
- Landing page is read-only (no authentication required)
- All API calls proxied through Nginx
- Security headers enabled
- No sensitive data exposed
- HTTPS recommended for production

## Performance
- Gzip compression enabled
- Static asset caching (1 year)
- Optimized CSS/JS delivery
- Minimal dependencies

## Future Enhancements
- [ ] Real-time WebSocket status updates
- [ ] Service health check integration
- [ ] User authentication (if needed)
- [ ] SSL/TLS certificate automation
- [ ] Multi-language support
- [ ] Dark/Light theme toggle
- [ ] Service metrics graphs

## Support
For issues or questions:
- Check logs: `docker logs landing-portal`
- Review Nginx config: `nginx.conf`
- Verify network: `docker network inspect ai_stack_net`

## Version
- **Version**: 1.0.0
- **Tier**: P1 Mission Critical
- **Last Updated**: 2026-02-07
