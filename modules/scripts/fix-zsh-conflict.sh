#!/usr/bin/env bash
# ZSH Configuration Conflict Resolution Script

set -euo pipefail

echo "🔍 Diagnosing ZSH configuration conflict..."

# Check current zshrc status
if [[ -f ~/.zshrc ]]; then
    echo "📄 Found existing ~/.zshrc"
    echo "📏 Size: $(wc -l ~/.zshrc | awk '{print $1}') lines"
    
    # Check if it's a symlink (home-manager managed)
    if [[ -L ~/.zshrc ]]; then
        echo "🔗 ~/.zshrc is a symlink (home-manager managed)"
        echo "🎯 Target: $(readlink ~/.zshrc)"
    else
        echo "📝 ~/.zshrc is a regular file (conflict source)"
        echo ""
        echo "🚨 CONFLICT: Home-manager wants to create a symlink but regular file exists"
        echo ""
        echo "📋 Current ~/.zshrc contents (first 10 lines):"
        head -10 ~/.zshrc
        echo ""
        
        # Backup and remove the conflicting file
        BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
        echo "💾 Backing up to: $BACKUP_FILE"
        cp ~/.zshrc "$BACKUP_FILE"
        
        echo "🗑️ Removing conflicting ~/.zshrc"
        rm ~/.zshrc
        
        echo "✅ Conflict resolved - home-manager can now create symlink"
    fi
else
    echo "✅ No ~/.zshrc exists - no conflict"
fi

# Check for other potential ZSH conflicts
echo ""
echo "🔍 Checking for other ZSH-related conflicts..."

ZSH_FILES=(
    ".zsh_history"
    ".zsh_sessions"
    ".zprofile" 
    ".zlogin"
    ".zlogout"
    ".zshenv"
)

for file in "${ZSH_FILES[@]}"; do
    if [[ -f "$HOME/$file" && -L "$HOME/$file" ]]; then
        echo "🔗 $file is symlinked (OK)"
    elif [[ -f "$HOME/$file" ]]; then
        echo "⚠️  $file exists as regular file (potential conflict)"
    else
        echo "✅ $file doesn't exist (OK)"
    fi
done

# Check home-manager ZSH configuration
echo ""
echo "🔍 Checking home-manager ZSH configuration..."

if command -v home-manager &> /dev/null; then
    echo "✅ home-manager command available"
    
    # Try a dry-run to see what home-manager wants to do
    echo "🧪 Testing home-manager activation (dry-run)..."
    if home-manager switch --dry-run 2>&1 | grep -i zsh; then
        echo "📋 Home-manager ZSH configuration found"
    else
        echo "❓ No obvious ZSH configuration in home-manager output"
    fi
else
    echo "❌ home-manager command not available"
fi

echo ""
echo "🎯 Next steps:"
echo "1. Try: sudo nixos-rebuild switch --flake .#heartwood-laptop"
echo "2. If successful, home-manager should activate automatically"
echo "3. If still failing, check the specific error message"

echo ""
echo "📞 If you need to restore your zshrc backup:"
echo "   cp $BACKUP_FILE ~/.zshrc"
