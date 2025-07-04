// Google OAuth Authentication for Jitsi Meet
// This file provides Google Sign-In functionality as a gate before joining meetings

class GoogleAuth {
    constructor(clientId, options = {}) {
        this.clientId = clientId;
        this.options = {
            allowedDomains: options.allowedDomains || [], // e.g., ['company.com']
            requireAuth: options.requireAuth !== false, // true by default
            redirectAfterAuth: options.redirectAfterAuth || null,
            ...options
        };
        this.currentUser = null;
        this.isInitialized = false;
    }

    // Initialize Google Sign-In
    async initialize() {
        return new Promise((resolve, reject) => {
            // Load Google Sign-In script
            if (!window.google) {
                const script = document.createElement('script');
                script.src = 'https://accounts.google.com/gsi/client';
                script.onload = () => this.initializeGoogleSignIn().then(resolve).catch(reject);
                script.onerror = () => reject(new Error('Failed to load Google Sign-In'));
                document.head.appendChild(script);
            } else {
                this.initializeGoogleSignIn().then(resolve).catch(reject);
            }
        });
    }

    async initializeGoogleSignIn() {
        return new Promise((resolve, reject) => {
            try {
                window.google.accounts.id.initialize({
                    client_id: this.clientId,
                    callback: this.handleCredentialResponse.bind(this),
                    auto_select: false,
                    cancel_on_tap_outside: true
                });
                
                this.isInitialized = true;
                console.log('Google OAuth initialized successfully');
                resolve();
            } catch (error) {
                console.error('Failed to initialize Google Sign-In:', error);
                reject(error);
            }
        });
    }

    // Handle Google Sign-In response
    handleCredentialResponse(response) {
        try {
            // Decode JWT token from Google
            const payload = this.parseJwt(response.credential);
            
            this.currentUser = {
                id: payload.sub,
                email: payload.email,
                name: payload.name,
                picture: payload.picture,
                verified: payload.email_verified
            };

            console.log('User signed in:', this.currentUser);
            
            // Check domain restrictions
            if (this.options.allowedDomains.length > 0) {
                const userDomain = payload.email.split('@')[1];
                if (!this.options.allowedDomains.includes(userDomain)) {
                    this.showError(`Access denied. Only users from ${this.options.allowedDomains.join(', ')} are allowed.`);
                    this.signOut();
                    return;
                }
            }

            // User authenticated successfully
            this.onAuthSuccess(this.currentUser);
            
        } catch (error) {
            console.error('Error handling Google sign-in:', error);
            this.showError('Authentication failed. Please try again.');
        }
    }

    // Parse JWT token
    parseJwt(token) {
        const base64Url = token.split('.')[1];
        const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/');
        const jsonPayload = decodeURIComponent(atob(base64).split('').map(function(c) {
            return '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2);
        }).join(''));
        return JSON.parse(jsonPayload);
    }

    // Show sign-in button
    showSignInButton(elementId = 'google-signin-button') {
        if (!this.isInitialized) {
            console.error('Google Auth not initialized. Call initialize() first.');
            return;
        }

        const element = document.getElementById(elementId);
        if (!element) {
            console.error(`Element with id '${elementId}' not found`);
            return;
        }

        window.google.accounts.id.renderButton(element, {
            theme: 'outline',
            size: 'large',
            text: 'sign_in_with',
            shape: 'rectangular',
            logo_alignment: 'left'
        });
    }

    // Show one-tap prompt
    showOneTap() {
        if (!this.isInitialized) {
            console.error('Google Auth not initialized');
            return;
        }
        window.google.accounts.id.prompt();
    }

    // Sign out
    signOut() {
        if (window.google && window.google.accounts) {
            window.google.accounts.id.disableAutoSelect();
        }
        this.currentUser = null;
        this.onAuthChange(null);
        console.log('User signed out');
    }

    // Check if user is authenticated
    isAuthenticated() {
        return this.currentUser !== null;
    }

    // Get current user
    getCurrentUser() {
        return this.currentUser;
    }

    // Events that can be overridden
    onAuthSuccess(user) {
        console.log('Authentication successful:', user);
        this.hideAuthUI();
        this.showJitsiMeet();
        this.onAuthChange(user);
    }

    onAuthChange(user) {
        // Override this method to handle auth state changes
        const event = new CustomEvent('googleAuthChange', { 
            detail: { user: user, isAuthenticated: !!user } 
        });
        document.dispatchEvent(event);
    }

    // UI Helper methods
    showError(message) {
        const errorDiv = document.getElementById('auth-error') || this.createErrorDiv();
        errorDiv.textContent = message;
        errorDiv.style.display = 'block';
        setTimeout(() => {
            errorDiv.style.display = 'none';
        }, 5000);
    }

    createErrorDiv() {
        const errorDiv = document.createElement('div');
        errorDiv.id = 'auth-error';
        errorDiv.style.cssText = `
            background: #f44336;
            color: white;
            padding: 10px;
            margin: 10px 0;
            border-radius: 4px;
            display: none;
        `;
        document.getElementById('auth-container')?.appendChild(errorDiv);
        return errorDiv;
    }

    hideAuthUI() {
        const authContainer = document.getElementById('auth-container');
        if (authContainer) {
            authContainer.style.display = 'none';
        }
    }

    showJitsiMeet() {
        // Show the main Jitsi Meet interface
        const jitsiContainer = document.getElementById('react');
        if (jitsiContainer) {
            jitsiContainer.style.display = 'block';
        }
        
        // Update user display name in Jitsi if possible
        if (this.currentUser && window.config) {
            window.config.defaultDisplayName = this.currentUser.name;
        }
    }

    // Method to require authentication before showing Jitsi
    requireAuth() {
        if (!this.options.requireAuth) {
            this.showJitsiMeet();
            return;
        }

        if (this.isAuthenticated()) {
            this.showJitsiMeet();
        } else {
            this.showAuthUI();
        }
    }

    showAuthUI() {
        // Hide Jitsi interface
        const jitsiContainer = document.getElementById('react');
        if (jitsiContainer) {
            jitsiContainer.style.display = 'none';
        }

        // Show auth interface
        let authContainer = document.getElementById('auth-container');
        if (!authContainer) {
            authContainer = this.createAuthUI();
        }
        authContainer.style.display = 'block';
    }

    createAuthUI() {
        const authContainer = document.createElement('div');
        authContainer.id = 'auth-container';
        authContainer.innerHTML = `
            <div style="
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                background: linear-gradient(135deg, #1e3c72 0%, #2a5298 100%);
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                color: white;
            ">
                <div style="
                    background: white;
                    padding: 40px;
                    border-radius: 12px;
                    box-shadow: 0 10px 30px rgba(0,0,0,0.3);
                    text-align: center;
                    max-width: 400px;
                    width: 90%;
                ">
                    <div style="color: #333; margin-bottom: 30px;">
                        <h2 style="margin: 0 0 10px 0; color: #1e3c72;">Welcome to Jitsi Meet</h2>
                        <p style="margin: 0; color: #666;">Please sign in with your Google account to continue</p>
                    </div>
                    
                    <div id="google-signin-button" style="margin: 20px 0;"></div>
                    
                    <div id="auth-error" style="display: none;"></div>
                    
                    <div style="margin-top: 20px; font-size: 12px; color: #999;">
                        Secure authentication powered by Google
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(authContainer);
        return authContainer;
    }
}

// Initialize Google Auth when page loads
let googleAuth = null;

document.addEventListener('DOMContentLoaded', function() {
    // Replace with your Google OAuth Client ID
    const GOOGLE_CLIENT_ID = window.GOOGLE_CLIENT_ID || 'YOUR_GOOGLE_CLIENT_ID';
    
    // Configuration options
    const authOptions = {
        requireAuth: true, // Set to false to make auth optional
        allowedDomains: [], // e.g., ['yourcompany.com'] to restrict to specific domains
    };

    // Initialize Google Auth
    googleAuth = new GoogleAuth(GOOGLE_CLIENT_ID, authOptions);
    
    googleAuth.initialize().then(() => {
        console.log('Google OAuth ready');
        googleAuth.requireAuth();
        
        // Show sign-in button if auth UI is visible
        setTimeout(() => {
            if (document.getElementById('google-signin-button')) {
                googleAuth.showSignInButton();
            }
        }, 100);
        
    }).catch(error => {
        console.error('Failed to initialize Google OAuth:', error);
        // Fallback: show Jitsi without auth
        googleAuth.showJitsiMeet();
    });
});

// Listen for auth state changes
document.addEventListener('googleAuthChange', function(event) {
    const { user, isAuthenticated } = event.detail;
    console.log('Auth state changed:', { user, isAuthenticated });
    
    // You can add custom logic here
    if (isAuthenticated) {
        console.log(`Welcome ${user.name}!`);
        // Optional: Send user info to your backend
        // sendUserToBackend(user);
    }
});

// Expose googleAuth globally for debugging
window.googleAuth = googleAuth; 