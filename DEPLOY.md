# Deploying Jitsi Meet to Render

This guide will help you deploy your Jitsi Meet application to Render using Docker.

## Overview

This deployment setup creates a containerized version of Jitsi Meet that can be deployed to Render. The configuration includes:

- Docker-based deployment
- Environment variable configuration
- Nginx web server for serving static assets
- Health checks and monitoring
- Customizable branding and features

## Prerequisites

1. **Render Account**: Sign up at [render.com](https://render.com)
2. **Git Repository**: Your Jitsi Meet code should be in a Git repository
3. **Docker Knowledge**: Basic understanding of Docker concepts

## Important Note

⚠️ **This deployment only provides the web interface for Jitsi Meet.** For full functionality, you'll need:

- **Prosody XMPP server** (for signaling)
- **Jicofo** (Jitsi Conference Focus)
- **Jitsi Videobridge** (JVB) (for media routing)
- **Jigasi** (for SIP/telephone integration) - optional
- **Jibri** (for recording/streaming) - optional

For testing purposes, the default configuration points to the public Jitsi Meet instance (`meet.jit.si`).

## Deployment Steps

### 1. Prepare Your Repository

Ensure your repository contains these files:
- `Dockerfile` - Multi-stage build configuration
- `docker-entrypoint.sh` - Container startup script
- `nginx.conf` - Nginx main configuration
- `default.conf` - Nginx server configuration
- `render.yaml` - Render deployment configuration
- `env.template` - Environment variables template

### 2. Configure Environment Variables

Review and customize the environment variables in `render.yaml`:

```yaml
envVars:
  - key: JITSI_DOMAIN
    value: your-domain.com
  - key: BOSH_URL
    value: https://your-jitsi-server.com/http-bind
  - key: WEBSOCKET_URL
    value: wss://your-jitsi-server.com/xmpp-websocket
  # ... other variables
```

### 3. Deploy to Render

#### Option A: Using render.yaml (Recommended)

1. **Push to Git**: Ensure all files are committed and pushed to your Git repository
2. **Import to Render**: 
   - Go to the Render Dashboard
   - Click "New" → "Blueprint"
   - Connect your Git repository
   - Render will automatically detect the `render.yaml` file

#### Option B: Manual Setup

1. **Create New Web Service**:
   - Go to Render Dashboard
   - Click "New" → "Web Service"
   - Connect your Git repository

2. **Configure Build Settings**:
   - **Environment**: Docker
   - **Dockerfile Path**: `./Dockerfile`
   - **Docker Context**: `./`

3. **Set Environment Variables**: Copy the variables from `env.template` and set them in the Render dashboard

### 4. Verify Deployment

After deployment:
1. Check the service logs for any errors
2. Visit your service URL
3. Try creating a test meeting room

## Configuration Options

### Domain Configuration

For production use, configure your own Jitsi Meet infrastructure:

```bash
# Your domain
JITSI_DOMAIN=meet.yourdomain.com

# XMPP domains
JITSI_MUC_DOMAIN=conference.meet.yourdomain.com
JITSI_FOCUS_DOMAIN=focus.meet.yourdomain.com

# Connection endpoints
BOSH_URL=https://meet.yourdomain.com/http-bind
WEBSOCKET_URL=wss://meet.yourdomain.com/xmpp-websocket
```

### Branding Configuration

Customize the appearance:

```bash
JITSI_MEET_TITLE=Your Company Meeting
JITSI_MEET_DESCRIPTION=Join our secure video conference
ENABLE_WELCOME_PAGE=true
ENABLE_JAAS_BRANDING=false
```

### Feature Configuration

Enable/disable features:

```bash
ENABLE_RECORDING=true
ENABLE_LIVE_STREAMING=true
ENABLE_TRANSCRIPTION=true
ENABLE_PREJOIN_PAGE=true
```

### Video Configuration

Adjust video settings:

```bash
RESOLUTION=1080
START_BITRATE=3000
DESKTOP_SHARING_FRAME_RATE=10
DISABLE_SIMULCAST=false
```

## Troubleshooting

### Common Issues

1. **Build Failures**
   - Check Node.js version compatibility (requires Node.js 22+)
   - Ensure all dependencies are available
   - Check Docker build logs

2. **Connection Issues**
   - Verify BOSH_URL and WEBSOCKET_URL are correct
   - Check CORS settings if using custom domains
   - Ensure WebSocket connections are allowed

3. **Missing Features**
   - Recording/streaming requires additional infrastructure
   - Authentication requires proper XMPP configuration
   - Some features need server-side components

### Debugging

Check the service logs:
```bash
# In Render dashboard, go to your service and check "Logs"
```

Access the health check endpoint:
```bash
curl https://your-app.onrender.com/health
```

## Performance Optimization

### Resource Planning

- **Starter Plan**: Suitable for testing/development
- **Standard Plan**: Good for small to medium deployments
- **Pro Plan**: Recommended for production use

### Scaling Considerations

- This deployment only handles the web interface
- For production, you'll need to scale the backend infrastructure
- Consider CDN for static assets
- Use load balancers for high availability

## Security Considerations

1. **HTTPS**: Always use HTTPS in production
2. **Content Security Policy**: Configured in nginx
3. **CORS**: Properly configured for your domain
4. **Environment Variables**: Keep sensitive data in environment variables

## Production Checklist

Before going live:

- [ ] Set up your own Jitsi Meet infrastructure
- [ ] Configure custom domain
- [ ] Set up SSL certificates
- [ ] Configure authentication if needed
- [ ] Set up monitoring and logging
- [ ] Test all features thoroughly
- [ ] Configure backup and disaster recovery
- [ ] Set up analytics (if needed)

## Support

For issues related to:
- **Jitsi Meet configuration**: Check [Jitsi Meet documentation](https://jitsi.github.io/handbook/)
- **Render deployment**: Check [Render documentation](https://render.com/docs)
- **Docker issues**: Check container logs and Docker documentation

## Additional Resources

- [Jitsi Meet Architecture](https://jitsi.github.io/handbook/docs/architecture)
- [Jitsi Meet Configuration](https://jitsi.github.io/handbook/docs/dev-guide/dev-guide-configuration)
- [Render Documentation](https://render.com/docs)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## License

This deployment configuration is provided under the same license as Jitsi Meet (Apache 2.0). 