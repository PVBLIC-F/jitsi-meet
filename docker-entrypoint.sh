#!/bin/bash
set -e

# Default values for environment variables
export JITSI_DOMAIN="${JITSI_DOMAIN:-meet.example.com}"
export JITSI_MUC_DOMAIN="${JITSI_MUC_DOMAIN:-conference.${JITSI_DOMAIN}}"
export JITSI_FOCUS_DOMAIN="${JITSI_FOCUS_DOMAIN:-focus.${JITSI_DOMAIN}}"
export JITSI_AUTH_DOMAIN="${JITSI_AUTH_DOMAIN:-auth.${JITSI_DOMAIN}}"
export JITSI_GUEST_DOMAIN="${JITSI_GUEST_DOMAIN:-guest.${JITSI_DOMAIN}}"
export BOSH_URL="${BOSH_URL:-https://${JITSI_DOMAIN}/http-bind}"
export WEBSOCKET_URL="${WEBSOCKET_URL:-wss://${JITSI_DOMAIN}/xmpp-websocket}"
export JITSI_MEET_TITLE="${JITSI_MEET_TITLE:-Jitsi Meet}"
export JITSI_MEET_DESCRIPTION="${JITSI_MEET_DESCRIPTION:-Join a WebRTC video conference powered by the Jitsi Videobridge}"
export DISABLE_HTTPS="${DISABLE_HTTPS:-false}"
export ENABLE_RECORDING="${ENABLE_RECORDING:-false}"
export ENABLE_LIVE_STREAMING="${ENABLE_LIVE_STREAMING:-false}"
export ENABLE_TRANSCRIPTION="${ENABLE_TRANSCRIPTION:-false}"
export RESOLUTION="${RESOLUTION:-720}"
export START_BITRATE="${START_BITRATE:-2500}"
export DESKTOP_SHARING_FRAME_RATE="${DESKTOP_SHARING_FRAME_RATE:-5}"
export DISABLE_SIMULCAST="${DISABLE_SIMULCAST:-false}"
export ENABLE_LAYER_SUSPENSION="${ENABLE_LAYER_SUSPENSION:-false}"
export ENABLE_STATS_ID="${ENABLE_STATS_ID:-false}"
export ENABLE_REMB="${ENABLE_REMB:-false}"
export ENABLE_TCC="${ENABLE_TCC:-false}"
export ENABLE_OPUS_RED="${ENABLE_OPUS_RED:-false}"
export ENABLE_AUDIO_LEVELS="${ENABLE_AUDIO_LEVELS:-true}"
export ENABLE_NOISY_MIC_DETECTION="${ENABLE_NOISY_MIC_DETECTION:-true}"
export ENABLE_NO_AUDIO_DETECTION="${ENABLE_NO_AUDIO_DETECTION:-true}"
export ENABLE_CLOSE_PAGE="${ENABLE_CLOSE_PAGE:-false}"
export ENABLE_PREJOIN_PAGE="${ENABLE_PREJOIN_PAGE:-false}"
export ENABLE_WELCOME_PAGE="${ENABLE_WELCOME_PAGE:-true}"
export ENABLE_GUEST_DOMAIN="${ENABLE_GUEST_DOMAIN:-false}"
export ENABLE_JAAS_BRANDING="${ENABLE_JAAS_BRANDING:-false}"

# Function to process SSI includes
process_ssi_includes() {
    local input_file="$1"
    local output_file="$2"
    
    # Copy the input file to output file
    cp "$input_file" "$output_file"
    
    # Process virtual includes
    sed -i 's|<!--#include virtual="/config.js" -->|<script src="config.js"></script>|g' "$output_file"
    sed -i 's|<!--#include virtual="/interface_config.js" -->|<script src="interface_config.js"></script>|g' "$output_file"
    sed -i 's|<!--#include virtual="head.html" -->||g' "$output_file"
    sed -i 's|<!--#include virtual="base.html" -->||g' "$output_file"
    sed -i 's|<!--#include virtual="fonts.html" -->||g' "$output_file"
    sed -i 's|<!--#include virtual="title.html" -->||g' "$output_file"
    sed -i 's|<!--#include virtual="plugin.head.html" -->||g' "$output_file"
    sed -i 's|<!--#include virtual="body.html" -->||g' "$output_file"
    sed -i 's|<!--#include virtual="static/.*" -->||g' "$output_file"
    
    # Process echo variables
    sed -i "s|<!--# echo var=\"subdir\" default=\"\" -->||g" "$output_file"
    sed -i "s|<!--# echo var=\"subdomain\" default=\"\" -->||g" "$output_file"
    sed -i "s|<!--# echo var=\"http_host\" default=\"jitsi-meet.example.com\" -->|${JITSI_DOMAIN}|g" "$output_file"
}

# Function to create config.js with environment variables
create_config_js() {
    cat > /usr/share/nginx/html/config.js << EOF
var config = {
    hosts: {
        domain: '${JITSI_DOMAIN}',
        muc: '${JITSI_MUC_DOMAIN}',
        focus: '${JITSI_FOCUS_DOMAIN}',
        ${ENABLE_GUEST_DOMAIN:+anonymousdomain: '${JITSI_GUEST_DOMAIN}',}
        ${ENABLE_GUEST_DOMAIN:+authdomain: '${JITSI_AUTH_DOMAIN}',}
    },
    
    bosh: '${BOSH_URL}',
    websocket: '${WEBSOCKET_URL}',
    
    // Disable https if specified
    ${DISABLE_HTTPS:+useStunTurn: true,}
    
    // Recording
    ${ENABLE_RECORDING:+fileRecordingsEnabled: true,}
    ${ENABLE_RECORDING:+recordingService: { enabled: true, sharingEnabled: true },}
    
    // Live streaming
    ${ENABLE_LIVE_STREAMING:+liveStreamingEnabled: true,}
    
    // Transcription
    ${ENABLE_TRANSCRIPTION:+transcribingEnabled: true,}
    
    // Video configuration
    resolution: ${RESOLUTION},
    constraints: {
        video: {
            height: {
                ideal: ${RESOLUTION},
                max: ${RESOLUTION},
                min: 240
            }
        }
    },
    
    // Bitrate configuration
    startBitrate: ${START_BITRATE},
    desktopSharingFrameRate: {
        min: ${DESKTOP_SHARING_FRAME_RATE},
        max: ${DESKTOP_SHARING_FRAME_RATE}
    },
    
    // Feature flags
    disableSimulcast: ${DISABLE_SIMULCAST},
    enableLayerSuspension: ${ENABLE_LAYER_SUSPENSION},
    enableStatsID: ${ENABLE_STATS_ID},
    enableRemb: ${ENABLE_REMB},
    enableTcc: ${ENABLE_TCC},
    enableOpusRed: ${ENABLE_OPUS_RED},
    disableAudioLevels: $([ "$ENABLE_AUDIO_LEVELS" = "false" ] && echo "true" || echo "false"),
    enableNoisyMicDetection: ${ENABLE_NOISY_MIC_DETECTION},
    enableNoAudioDetection: ${ENABLE_NO_AUDIO_DETECTION},
    enableClosePage: ${ENABLE_CLOSE_PAGE},
    enableWelcomePage: ${ENABLE_WELCOME_PAGE},
    
    // Prejoin page
    ${ENABLE_PREJOIN_PAGE:+prejoinPageEnabled: true,}
    
    // JaaS branding
    ${ENABLE_JAAS_BRANDING:+enableJaaSBranding: true,}
    
    // Default configuration
    enableUserRolesBasedOnToken: false,
    enableFeaturesBasedOnToken: false,
    enableInsecureRoomNameWarning: false,
    enableAutomaticUrlCopy: false,
    requireDisplayName: false,
    
    // P2P configuration
    p2p: {
        enabled: true,
        stunServers: [
            { urls: 'stun:stun.l.google.com:19302' },
            { urls: 'stun:stun1.l.google.com:19302' }
        ],
        preferH264: true,
        preferredCodec: 'VP8',
        disableH264: false,
        useStunTurn: true
    },
    
    // Analytics
    analytics: {
        disabled: true
    },
    
    // Disable third party requests
    disableThirdPartyRequests: false,
    
    // Testing
    testing: {
        p2pTestMode: false,
        testMode: false,
        noAutoPlayVideo: false
    }
};

// Make config available globally
if (typeof module !== 'undefined' && module.exports) {
    module.exports = config;
}
EOF
}

# Function to create interface_config.js with environment variables
create_interface_config_js() {
    cat > /usr/share/nginx/html/interface_config.js << EOF
var interfaceConfig = {
    APP_NAME: '${JITSI_MEET_TITLE}',
    
    // Toolbar configuration
    TOOLBAR_BUTTONS: [
        'microphone', 'camera', 'closedcaptions', 'desktop', 'embedmeeting',
        'fullscreen', 'fodeviceselection', 'hangup', 'profile', 'info', 'chat',
        'recording', 'livestreaming', 'etherpad', 'sharedvideo', 'settings',
        'raisehand', 'videoquality', 'filmstrip', 'invite', 'feedback', 'stats',
        'shortcuts', 'tileview', 'videobackgroundblur', 'download', 'help',
        'mute-everyone', 'e2ee', 'security'
    ],
    
    // Settings sections
    SETTINGS_SECTIONS: [
        'devices', 'language', 'moderator', 'profile', 'calendar', 'sounds', 'more'
    ],
    
    // Video layout configuration
    VIDEO_LAYOUT_FIT: 'both',
    filmStripOnly: false,
    
    // UI configuration
    GENERATE_ROOMNAMES_ON_WELCOME_PAGE: true,
    DISPLAY_WELCOME_PAGE_CONTENT: ${ENABLE_WELCOME_PAGE},
    DISPLAY_WELCOME_PAGE_TOOLBAR_ADDITIONAL_CONTENT: false,
    DISPLAY_WELCOME_FOOTER: true,
    SHOW_JITSI_WATERMARK: false,
    SHOW_WATERMARK_FOR_GUESTS: false,
    SHOW_BRAND_WATERMARK: false,
    BRAND_WATERMARK_LINK: '',
    SHOW_POWERED_BY: false,
    SHOW_PROMOTIONAL_CLOSE_PAGE: ${ENABLE_CLOSE_PAGE},
    RANDOM_AVATAR_URL_PREFIX: false,
    RANDOM_AVATAR_URL_SUFFIX: false,
    FILM_STRIP_MAX_HEIGHT: 120,
    ENABLE_FEEDBACK_ANIMATION: false,
    DISABLE_FOCUS_INDICATOR: false,
    DISABLE_DOMINANT_SPEAKER_INDICATOR: false,
    DISABLE_TRANSCRIPTION_SUBTITLES: false,
    DISABLE_RINGING: false,
    AUDIO_LEVEL_PRIMARY_COLOR: 'rgba(255,255,255,0.4)',
    AUDIO_LEVEL_SECONDARY_COLOR: 'rgba(255,255,255,0.2)',
    POLICY_LOGO: null,
    LOCAL_THUMBNAIL_RATIO: 16 / 9,
    REMOTE_THUMBNAIL_RATIO: 1,
    LIVE_STREAMING_HELP_LINK: 'https://jitsi.org/live',
    MOBILE_APP_PROMO: false,
    MAXIMUM_ZOOMING_COEFFICIENT: 1.3,
    SUPPORT_URL: 'https://community.jitsi.org/',
    CONNECTION_INDICATOR_AUTO_HIDE_ENABLED: true,
    CONNECTION_INDICATOR_AUTO_HIDE_TIMEOUT: 5000,
    CONNECTION_INDICATOR_DISABLED: false,
    VIDEO_QUALITY_LABEL_DISABLED: false,
    RECENT_LIST_ENABLED: true,
    OPTIMAL_BROWSERS: [
        'chrome', 'chromium', 'firefox', 'nwjs', 'electron', 'safari'
    ],
    UNSUPPORTED_BROWSERS: [],
    AUTO_PIN_LATEST_SCREEN_SHARE: 'remote-only',
    DISABLE_PRESENCE_STATUS: false,
    DISABLE_JOIN_LEAVE_NOTIFICATIONS: false,
    HIDE_KICK_BUTTON_FOR_GUESTS: false,
    TILE_VIEW_MAX_COLUMNS: 5
};

// Make interface config available globally
if (typeof module !== 'undefined' && module.exports) {
    module.exports = interfaceConfig;
}
EOF
}

# Function to update title in HTML
update_title() {
    if [ -f /usr/share/nginx/html/index.html ]; then
        sed -i "s|<title>.*</title>|<title>${JITSI_MEET_TITLE}</title>|g" /usr/share/nginx/html/index.html
    fi
}

# Function to update meta description
update_meta_description() {
    if [ -f /usr/share/nginx/html/index.html ]; then
        sed -i "s|<meta name=\"description\" content=\".*\">|<meta name=\"description\" content=\"${JITSI_MEET_DESCRIPTION}\">|g" /usr/share/nginx/html/index.html
    fi
}

# Main execution
echo "Starting Jitsi Meet container..."
echo "Domain: ${JITSI_DOMAIN}"
echo "MUC Domain: ${JITSI_MUC_DOMAIN}"
echo "BOSH URL: ${BOSH_URL}"
echo "WebSocket URL: ${WEBSOCKET_URL}"

# Process index.html with SSI includes
echo "Processing index.html..."
if [ -f /usr/share/nginx/html/index.html ]; then
    process_ssi_includes /usr/share/nginx/html/index.html /usr/share/nginx/html/index.html.processed
    mv /usr/share/nginx/html/index.html.processed /usr/share/nginx/html/index.html
fi

# Create configuration files
echo "Creating configuration files..."
create_config_js
create_interface_config_js

# Update HTML metadata
echo "Updating HTML metadata..."
update_title
update_meta_description

# Process nginx configuration with environment variables
echo "Processing nginx configuration..."
envsubst '\$BOSH_URL \$WEBSOCKET_URL' < /etc/nginx/conf.d/default.conf > /etc/nginx/conf.d/default.conf.tmp
mv /etc/nginx/conf.d/default.conf.tmp /etc/nginx/conf.d/default.conf

# Test nginx configuration
echo "Testing nginx configuration..."
nginx -t

echo "Starting nginx..."
exec "$@" 