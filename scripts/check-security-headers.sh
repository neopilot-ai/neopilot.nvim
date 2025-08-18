#!/bin/bash

# Check security headers for the web interface
# Exit with error if any critical security headers are missing

set -e

# Default values
PORT=${PORT:-3000}
HOST=${HOST:-localhost}
PROTOCOL=${PROTOCOL:-http}
TIMEOUT=${TIMEOUT:-10}

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "Error: curl is required but not installed"
    exit 1
fi

# Function to check if header is present
check_header() {
    local header_name=$1
    local header_value=$2
    local url="$PROTOCOL://$HOST:$PORT"
    
    echo "Checking $header_name header..."
    
    if ! headers=$(curl -sI -m $TIMEOUT "$url"); then
        echo "Error: Could not connect to $url"
        return 1
    fi
    
    if ! echo "$headers" | grep -qi "^$header_name:"; then
        echo "❌ $header_name header is missing"
        return 1
    fi
    
    if [ -n "$header_value" ]; then
        if ! echo "$headers" | grep -i "^$header_name:.*$header_value" &> /dev/null; then
            echo "❌ $header_name header has incorrect value"
            echo "   Expected: $header_value"
            echo "   Found: $(echo "$headers" | grep -i "^$header_name:" | cut -d ' ' -f 2-)"
            return 1
        fi
    fi
    
    echo "✅ $header_name header is properly configured"
    return 0
}

# Check security headers
check_header "X-Content-Type-Options" "nosniff"
check_header "X-Frame-Options" "DENY"
check_header "X-XSS-Protection" "1; mode=block"
check_header "Referrer-Policy" "strict-origin-when-cross-origin"
check_header "Content-Security-Policy" ""
check_header "Strict-Transport-Security" "max-age=63072000; includeSubDomains; preload"

# Check if server is leaking information
if curl -sI "$PROTOCOL://$HOST:$PORT" | grep -i "^server:\|^x-powered-by:" | grep -v "^$"; then
    echo "⚠️  Server information is being leaked in headers"
    echo "   Consider removing Server and X-Powered-By headers"
fi

echo "\nSecurity header check completed"
