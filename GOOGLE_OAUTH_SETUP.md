# Google OAuth Setup Guide

This guide will help you add Google OAuth authentication to your Jitsi Meet deployment.

## Overview

The Google OAuth integration provides:
- ✅ **Secure Authentication**: Users sign in with their Google accounts
- ✅ **Domain Restrictions**: Optionally limit access to specific domains (e.g., your company)
- ✅ **Beautiful UI**: Clean, modern authentication interface
- ✅ **Easy Setup**: Works with your current deployment
- ✅ **No Backend Required**: Pure client-side implementation

## Step 1: Create Google OAuth Credentials

### 1.1 Go to Google Cloud Console
1. Visit [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the Google+ API (if not already enabled)

### 1.2 Create OAuth 2.0 Credentials
1. Go to **APIs & Services** → **Credentials**
2. Click **+ CREATE CREDENTIALS** → **OAuth 2.0 Client IDs**
3. Configure the consent screen if prompted:
   - **Application name**: Your App Name (e.g., "My Jitsi Meet")
   - **User support email**: Your email
   - **Authorized domains**: `onrender.com` (add your custom domain if you have one)

### 1.3 Configure OAuth Client ID
1. **Application type**: Web application
2. **Name**: Jitsi Meet OAuth Client
3. **Authorized JavaScript origins**:
   - `https://jitsi-meet-akqz.onrender.com`
   - Add your custom domain if you have one
4. **Authorized redirect URIs**: (leave empty for this implementation)
5. Click **CREATE**
6. **Copy the Client ID** - you'll need this!

## Step 2: Configure Your Deployment

### 2.1 Update Environment Variables
In your Render dashboard or `render.yaml`, set these variables:

```yaml
envVars:
  # Enable Google OAuth
  - key: ENABLE_GOOGLE_AUTH
    value: "true"
  
  # Your Google OAuth Client ID (from Step 1)
  - key: GOOGLE_CLIENT_ID
    value: "your-client-id-here.apps.googleusercontent.com"
  
  # Optional: Restrict to specific domains
  - key: GOOGLE_ALLOWED_DOMAINS
    value: "company.com,partner.org"  # comma-separated list
```

### 2.2 Deploy the Changes
After updating the environment variables:
1. **Commit and push** your code changes
2. **Redeploy** on Render
3. The authentication will be automatically enabled

## Step 3: Test the Authentication

### 3.1 Visit Your Application
1. Go to `https://jitsi-meet-akqz.onrender.com`
2. You should see a Google Sign-In page instead of going directly to Jitsi Meet
3. Click **Sign in with Google**
4. Complete the Google authentication flow
5. You should be redirected to the Jitsi Meet interface

### 3.2 Test Domain Restrictions (if configured)
1. Try signing in with an account from an allowed domain ✅
2. Try signing in with an account from a non-allowed domain ❌
3. Verify the appropriate error message is shown

## Configuration Options

### Domain Restrictions
```yaml
# Allow only specific domains
- key: GOOGLE_ALLOWED_DOMAINS
  value: "company.com,partner.org"

# Allow all domains (leave empty)
- key: GOOGLE_ALLOWED_DOMAINS
  value: ""
```

### Disable Authentication
```yaml
# Disable Google OAuth (everyone can access)
- key: ENABLE_GOOGLE_AUTH
  value: "false"
```

## Customization

### Custom Styling
You can customize the authentication UI by modifying `google-auth.js`:

```javascript
// In the createAuthUI() method, update the styles:
background: linear-gradient(135deg, #your-color1 0%, #your-color2 100%);
```

### Custom Domain Requirements
If you have specific domain requirements, modify the `allowedDomains` array in the Google Auth configuration.

### User Information Access
The authenticated user information is available globally:

```javascript
// Access current user
const user = window.googleAuth?.getCurrentUser();
if (user) {
    console.log('User:', user.name, user.email);
}

// Listen for auth changes
document.addEventListener('googleAuthChange', function(event) {
    const { user, isAuthenticated } = event.detail;
    // Handle auth state changes
});
```

## Troubleshooting

### "Sign-in failed" Error
**Cause**: Invalid Client ID or domain mismatch
**Solution**: 
1. Verify your `GOOGLE_CLIENT_ID` is correct
2. Check that your domain is added to authorized origins
3. Make sure you're using HTTPS

### "Access denied" Message
**Cause**: User's domain not in allowed list
**Solution**: Add their domain to `GOOGLE_ALLOWED_DOMAINS` or remove domain restrictions

### Authentication UI Not Showing
**Cause**: Google OAuth not enabled or script not loading
**Solution**: 
1. Verify `ENABLE_GOOGLE_AUTH=true`
2. Check browser console for errors
3. Verify `google-auth.js` is accessible

### Users Can Skip Authentication
**Cause**: This is expected behavior - this implementation is client-side only
**For server-side security**: You need a backend service to validate tokens

## Security Considerations

### Client-Side vs Server-Side
- ✅ **Current implementation**: Client-side authentication gate
- ✅ **Good for**: Access control, user identification, demo/internal use
- ⚠️ **Not cryptographically secure**: Determined users can bypass
- 🔒 **For maximum security**: Implement server-side JWT validation

### Production Recommendations
1. **Use HTTPS**: Required for Google OAuth
2. **Validate domains**: Use `GOOGLE_ALLOWED_DOMAINS` for company use
3. **Monitor access**: Check deployment logs for auth events
4. **Regular updates**: Keep Google OAuth library updated

### Upgrading to Server-Side Auth
When you're ready for full backend integration:
1. Set up your own Jitsi infrastructure
2. Implement JWT token validation on the server
3. Use the Google OAuth tokens to generate Jitsi JWT tokens

## Example Configurations

### Company Internal Use
```yaml
envVars:
  - key: ENABLE_GOOGLE_AUTH
    value: "true"
  - key: GOOGLE_CLIENT_ID
    value: "your-client-id.apps.googleusercontent.com"
  - key: GOOGLE_ALLOWED_DOMAINS
    value: "yourcompany.com"
```

### Public with Optional Auth
```yaml
envVars:
  - key: ENABLE_GOOGLE_AUTH
    value: "false"  # Users can join without authentication
```

### Partner Collaboration
```yaml
envVars:
  - key: ENABLE_GOOGLE_AUTH
    value: "true"
  - key: GOOGLE_CLIENT_ID
    value: "your-client-id.apps.googleusercontent.com"
  - key: GOOGLE_ALLOWED_DOMAINS
    value: "company.com,partner1.com,partner2.org"
```

## Support

If you encounter issues:
1. Check the browser console for errors
2. Verify your Google Cloud Console configuration
3. Test with different Google accounts
4. Check the deployment logs for auth-related messages

The Google OAuth integration should now be working with your Jitsi Meet deployment! 🎉 