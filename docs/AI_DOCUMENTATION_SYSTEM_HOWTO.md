# AI Documentation System - Complete How-To Guide

**Purpose:** Comprehensive guide for using, troubleshooting, and maintaining the AI-enhanced documentation system  
**Last Updated:** 2025-08-06  
**System:** NixOS Homeserver with Ollama + llama3.2:3b

---

## 📖 **How It Works**

### **System Overview**
The AI documentation system automatically generates intelligent documentation from git commits using local AI processing. Every time you commit changes, the system:

1. **Captures commit data** (hash, message, diff) via git post-commit hook
2. **Analyzes changes** with local Ollama AI (llama3.2:3b model)
3. **Generates documentation** including technical summaries and system evolution narratives
4. **Updates documentation files** automatically

### **Workflow Diagram**
```
git commit → post-commit hook → AI analysis → documentation update → auto-commit (optional)
```

---

## 🚀 **How to Use**

### **Standard Workflow**
```bash
# Make your configuration changes
sudo micro /etc/nixos/hosts/server/config.nix

# Use enhanced grebuild (includes AI documentation)
grebuild "Add new surveillance camera configuration"

# Check generated documentation
cat /etc/nixos/docs/SYSTEM_CHANGELOG.md
cat /etc/nixos/docs/ai-doc-generation.log
```

### **Manual AI Generation**
```bash
# Run AI documentation generator directly
bash /etc/nixos/scripts/ai-docs-wrapper.sh

# Check if Ollama is responsive
curl http://localhost:11434/api/tags
```

### **View Generated Documentation**
```bash
# System changelog (structured commit history)
less /etc/nixos/docs/SYSTEM_CHANGELOG.md

# AI processing logs
less /etc/nixos/docs/ai-doc-generation.log

# Updated system primer (AI-enhanced)
less /etc/nixos/docs/CLAUDE_CODE_SYSTEM_PRIMER.md
```

---

## ⚙️ **System Components**

### **1. Git Post-Commit Hook**
- **File:** `/etc/nixos/.git/hooks/post-commit`
- **Trigger:** Executes automatically after every `git commit`
- **Function:** Captures commit metadata and triggers AI processing

### **2. AI Documentation Generator**
- **File:** `/etc/nixos/scripts/ai-narrative-docs.py`
- **Model:** Uses Ollama with llama3.2:3b for local AI processing
- **Capabilities:**
  - Analyzes commit diffs for technical changes
  - Generates system evolution narratives
  - Creates structured documentation updates
  - Handles errors gracefully with fallback text

### **3. Python Environment Wrapper**
- **File:** `/etc/nixos/scripts/ai-docs-wrapper.sh`
- **Purpose:** Ensures correct Python environment with required packages
- **Packages:** requests, urllib3, idna, charset-normalizer

### **4. Enhanced grebuild Function**
- **Location:** `/etc/nixos/shared/zsh-config.nix`
- **Enhancement:** Provides feedback about AI documentation generation
- **Integration:** Seamlessly works with existing safety features

---

## 🔧 **Configuration Details**

### **Ollama Service**
```bash
# Check service status
systemctl status ollama

# Available models
ollama list

# Test AI interaction
curl -X POST http://localhost:11434/api/generate \\
  -H "Content-Type: application/json" \\
  -d '{"model": "llama3.2:3b", "prompt": "Test", "stream": false}'
```

### **Python Environment**
The system uses NixOS-managed Python packages declared in:
```nix
# /etc/nixos/hosts/server/modules/ai-services.nix
environment.systemPackages = with pkgs; [
  python3Packages.requests
  python3Packages.urllib3
  python3Packages.idna
  python3Packages.charset-normalizer
];
```

### **File Permissions**
```bash
# Required permissions
chmod +x /etc/nixos/.git/hooks/post-commit
chmod +x /etc/nixos/scripts/ai-narrative-docs.py
chmod +x /etc/nixos/scripts/ai-docs-wrapper.sh
chmod 644 /etc/nixos/docs/SYSTEM_CHANGELOG.md
chmod 644 /etc/nixos/docs/ai-doc-generation.log
```

---

## 🚨 **Common Issues & Troubleshooting**

### **Issue 1: "ModuleNotFoundError: No module named 'requests'"**

**Symptoms:**
```
Traceback (most recent call last):
  File "/etc/nixos/scripts/ai-narrative-docs.py", line 10, in <module>
    import requests
ModuleNotFoundError: No module named 'requests'
```

**Cause:** Python packages not properly installed or not in path

**Solutions:**
```bash
# Check if packages are in system environment
/run/current-system/sw/bin/python3 -c "import requests"

# If missing, verify ai-services.nix includes packages
grep -n "python3Packages.requests" /etc/nixos/hosts/server/modules/ai-services.nix

# Rebuild system to activate packages
sudo nixos-rebuild switch --flake .#hwc-server

# Reload shell environment
source ~/.zshrc
```

### **Issue 2: "bad interpreter: /bin/bash: no such file or directory"**

**Symptoms:**
```
(eval):1: /etc/nixos/.git/hooks/post-commit: bad interpreter: /bin/bash: no such file or directory
```

**Cause:** Incorrect shebang path for NixOS

**Solution:**
```bash
# Fix shebang in post-commit hook
sed -i '1s|#!/bin/bash|#!/usr/bin/env bash|' /etc/nixos/.git/hooks/post-commit
```

### **Issue 3: "insufficient permission for adding an object to repository database"**

**Symptoms:**
```
error: insufficient permission for adding an object to repository database .git/objects
```

**Cause:** Git ownership/permission issues

**Solutions:**
```bash
# Fix git directory ownership
sudo chown -R eric:users /etc/nixos/.git

# Or disable auto-commit in post-commit hook
# Comment out the git add/commit section in post-commit hook
```

### **Issue 4: Ollama Not Responding**

**Symptoms:**
```
requests.exceptions.ConnectionError: HTTPConnectionPool(host='localhost', port=11434)
```

**Solutions:**
```bash
# Check Ollama service
systemctl status ollama
sudo systemctl restart ollama

# Check if models are available
ollama list

# Test connectivity
curl http://localhost:11434/api/tags

# Pull required model if missing
ollama pull llama3.2:3b
```

### **Issue 5: AI Generation Takes Too Long**

**Symptoms:** Git commits hang or take >30 seconds

**Solutions:**
```bash
# Check GPU acceleration
nvidia-smi

# Monitor Ollama logs
sudo journalctl -fu ollama

# Test model performance
time ollama run llama3.2:3b "Quick test"

# Consider switching to lighter model if needed
```

### **Issue 6: Generated Documentation is Low Quality**

**Solutions:**
```bash
# Check if model is loaded correctly
ollama list

# Verify system prompt in AI script
grep -A 10 "system_prompt" /etc/nixos/scripts/ai-narrative-docs.py

# Test model directly
ollama run llama3.2:3b "Explain what a NixOS configuration change does"
```

---

## 🔍 **Debugging Commands**

### **System Health Check**
```bash
# Full system status
echo "=== Ollama Service ==="
systemctl status ollama --no-pager

echo "=== Available Models ==="
ollama list

echo "=== Python Environment ==="
which python3
python3 --version

echo "=== Git Hook Status ==="
ls -la /etc/nixos/.git/hooks/post-commit

echo "=== AI Script Status ==="
ls -la /etc/nixos/scripts/ai-*

echo "=== Recent AI Logs ==="
tail -20 /etc/nixos/docs/ai-doc-generation.log
```

### **Test AI Pipeline Manually**
```bash
# Test each component individually
echo "Testing Ollama API..."
curl -X POST http://localhost:11434/api/generate -H "Content-Type: application/json" -d '{"model": "llama3.2:3b", "prompt": "Say test successful", "stream": false}'

echo "Testing Python environment..."
bash /etc/nixos/scripts/ai-docs-wrapper.sh

echo "Testing git hook..."
/etc/nixos/.git/hooks/post-commit
```

### **Performance Monitoring**
```bash
# Monitor GPU usage during AI generation
watch -n 1 nvidia-smi

# Monitor system resources
htop

# Check Ollama performance
curl -s http://localhost:11434/api/ps
```

---

## 🛠️ **Maintenance**

### **Regular Maintenance**
```bash
# Clean up old changelog entries (optional)
# Keep last 50 commits in SYSTEM_CHANGELOG.md
tail -n 2000 /etc/nixos/docs/SYSTEM_CHANGELOG.md > /tmp/changelog_tmp
mv /tmp/changelog_tmp /etc/nixos/docs/SYSTEM_CHANGELOG.md

# Rotate AI logs
logrotate /etc/nixos/docs/ai-doc-generation.log

# Update Ollama models
ollama pull llama3.2:3b
```

### **Backup Important Files**
```bash
# Backup AI system components
tar -czf /etc/nixos/backup/ai-docs-$(date +%Y%m%d).tar.gz \\
  /etc/nixos/scripts/ai-* \\
  /etc/nixos/.git/hooks/post-commit \\
  /etc/nixos/docs/SYSTEM_CHANGELOG.md
```

---

## 🎛️ **Advanced Configuration**

### **Customize AI Prompts**
Edit `/etc/nixos/scripts/ai-narrative-docs.py`:
```python
# Modify system prompts on lines ~153, ~200, ~225, ~252
system_prompt = """Your custom prompt here..."""
```

### **Change AI Model**
```python
# In ai-narrative-docs.py, change model name:
self.model = "llama3.2:1b"  # For faster processing
# or
self.model = "llama3.2:7b"  # For better quality
```

### **Adjust Processing Frequency**
```bash
# To process only major commits, modify post-commit hook:
# Add conditions like checking commit message keywords
if [[ "$COMMIT_MSG" == *"MAJOR"* ]]; then
    # Run AI processing
fi
```

---

## 📋 **Quick Reference**

### **Key Files**
| File | Purpose |
|------|---------|
| `/etc/nixos/.git/hooks/post-commit` | Git hook trigger |
| `/etc/nixos/scripts/ai-narrative-docs.py` | Main AI processing |
| `/etc/nixos/scripts/ai-docs-wrapper.sh` | Python environment wrapper |
| `/etc/nixos/docs/SYSTEM_CHANGELOG.md` | Structured commit history |
| `/etc/nixos/docs/ai-doc-generation.log` | AI processing logs |

### **Key Commands**
| Command | Purpose |
|---------|---------|
| `grebuild "message"` | Enhanced git commit with AI docs |
| `bash /etc/nixos/scripts/ai-docs-wrapper.sh` | Manual AI generation |
| `ollama list` | Check available AI models |
| `systemctl status ollama` | Check AI service |
| `tail /etc/nixos/docs/ai-doc-generation.log` | View AI logs |

### **Emergency Disable**
```bash
# Temporarily disable AI processing
chmod -x /etc/nixos/.git/hooks/post-commit

# Re-enable
chmod +x /etc/nixos/.git/hooks/post-commit
```

---

**For support or questions about the AI documentation system, check the logs first, then refer to this troubleshooting guide.**