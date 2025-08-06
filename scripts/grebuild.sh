#!/usr/bin/env bash
# Enhanced grebuild function - Fast git workflow + rebuild, then AI processing

set -e

if [ $# -eq 0 ]; then
    echo "Usage: grebuild \"commit message\""
    exit 1
fi

COMMIT_MESSAGE="$1"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "🚀 Starting grebuild workflow..."
echo "📝 Commit message: $COMMIT_MESSAGE"

# Step 1: Git operations (fast)
echo "📦 Adding changes to git..."
sudo git add .

echo "💾 Committing changes..."
sudo git commit -m "$COMMIT_MESSAGE"

# Step 2: Test rebuild first (safety check)
echo "🧪 Testing NixOS configuration..."
if sudo nixos-rebuild test --flake .#hwc-server; then
    echo "✅ Test successful!"
    
    # Step 3: Apply rebuild
    echo "🔄 Applying NixOS rebuild..."
    if sudo nixos-rebuild switch --flake .#hwc-server; then
        echo "✅ Rebuild successful!"
        
        # Step 4: Push to remote
        echo "📤 Pushing to remote repository..."
        sudo git push
        
        # Step 5: Trigger AI documentation (non-blocking)
        echo "🤖 Triggering AI documentation processing..."
        sudo systemctl start post-rebuild-ai-docs &
        
        # Send completion notification
        curl -s -H "Title: ✅ NixOS Rebuild Complete" \
             -d "Successfully rebuilt and deployed: $COMMIT_MESSAGE" \
             https://hwc.ocelot-wahoo.ts.net/notify/hwc-alerts 2>/dev/null || true
        
        echo "🎉 Grebuild complete! AI documentation running in background."
        echo "📱 You'll receive a notification when AI docs are updated."
        
    else
        echo "❌ Rebuild failed!"
        exit 1
    fi
else
    echo "❌ Test failed! Not proceeding with rebuild."
    exit 1
fi
