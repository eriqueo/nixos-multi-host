# AI-Enhanced Documentation System Implementation Plan

**Created:** 2025-08-05  
**System:** hwc-server (NixOS)  
**Purpose:** Complete implementation guide for AI-powered documentation system using local Ollama

---

## 🎯 **Overview**

This document provides a complete implementation plan for an AI-enhanced documentation system that automatically generates narrative documentation from git commits using local Ollama AI processing.

### **Goals**
- Automatically capture all git changes in a structured changelog
- Use local AI (Ollama) to analyze commits and generate intelligent narratives
- Keep documentation synchronized with actual system state
- Provide rollback capability if implementation fails

---

## 🏗️ **System Architecture**

```
Git Commit → Post-Commit Hook → Capture Diff → AI Analysis (Ollama) → Update Docs → Auto-Commit Docs
```

### **Components**
1. **Git Post-Commit Hook** - Captures diffs and metadata
2. **System Changelog** - Structured log of all changes
3. **AI Documentation Generator** - Python script using Ollama API
4. **Enhanced grebuild Function** - Integrates AI processing
5. **Automated Doc Updates** - Smart updates to existing .md files

---

## 📋 **Implementation Checklist**

### **Phase 1: Core Infrastructure**
- [ ] Create `/etc/nixos/scripts/` directory
- [ ] Create AI documentation generator script
- [ ] Create initial `SYSTEM_CHANGELOG.md`
- [ ] Set up git post-commit hook
- [ ] Set proper file permissions

### **Phase 2: Integration**
- [ ] Update grebuild function with AI integration
- [ ] Test AI system with dummy commit
- [ ] Verify Ollama connectivity and model availability

### **Phase 3: Validation**
- [ ] Create test commit to verify full pipeline
- [ ] Check generated documentation quality
- [ ] Verify backup and rollback procedures

---

## 📄 **File Structure**

```
/etc/nixos/
├── scripts/
│   └── ai-narrative-docs.py          # Main AI generator
├── docs/
│   ├── SYSTEM_CHANGELOG.md           # Structured commit log
│   └── AI_DOCUMENTATION_IMPLEMENTATION_PLAN.md  # This file
└── .git/hooks/
    └── post-commit                    # Auto-capture hook
```

---

## 🤖 **AI Documentation Generator Script**

**File:** `/etc/nixos/scripts/ai-narrative-docs.py`

```python
#!/usr/bin/env python3
# AI-Enhanced Documentation Generator for NixOS
# Uses local Ollama for intelligent commit analysis

import json
import re
import subprocess
from pathlib import Path
from datetime import datetime
import requests

class AIDocumentationGenerator:
    def __init__(self):
        self.changelog_path = Path("/etc/nixos/docs/SYSTEM_CHANGELOG.md")
        self.docs_path = Path("/etc/nixos/docs")
        self.ollama_url = "http://localhost:11434/api/generate"
        self.model = "llama3.2:3b"  # Fast local model for hwc-server
        
    def call_ollama(self, prompt, system_prompt=None):
        """Call local Ollama API for AI analysis"""
        payload = {
            "model": self.model,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.3,  # Low temperature for consistent technical writing
                "top_p": 0.9,
                "num_ctx": 4096  # Larger context for code analysis
            }
        }
        
        if system_prompt:
            payload["system"] = system_prompt
            
        try:
            print(f"🤖 Calling Ollama with model {self.model}...")
            response = requests.post(self.ollama_url, json=payload, timeout=60)
            response.raise_for_status()
            result = response.json()["response"].strip()
            print(f"✅ AI analysis complete ({len(result)} chars)")
            return result
        except Exception as e:
            print(f"⚠️ Ollama call failed: {e}")
            return None
    
    def test_ollama_connection(self):
        """Test if Ollama is accessible and model is available"""
        try:
            # Test basic connectivity
            test_response = requests.get("http://localhost:11434/api/tags", timeout=10)
            test_response.raise_for_status()
            
            models = test_response.json().get("models", [])
            available_models = [m["name"] for m in models]
            
            print(f"📡 Ollama connected. Available models: {available_models}")
            
            if self.model not in available_models:
                print(f"⚠️ Model {self.model} not found. Using first available model.")
                if available_models:
                    self.model = available_models[0]
                else:
                    print("❌ No models available in Ollama")
                    return False
            
            # Test actual generation
            test_result = self.call_ollama("Say 'test successful' if you can read this.")
            return test_result is not None
            
        except Exception as e:
            print(f"❌ Ollama connection test failed: {e}")
            return False
    
    def analyze_commit_with_ai(self, commit):
        """Use AI to analyze what a commit actually does"""
        
        system_prompt = """You are a technical documentation expert for NixOS systems. 
        Analyze git commits and explain what they accomplish in clear, concise language.
        Focus on:
        - What services/containers were added/removed/modified
        - What capabilities were enhanced (GPU, storage, networking, etc.)
        - What problems were likely solved
        - Impact on system functionality
        
        Be specific and technical but readable. No emojis. Maximum 2 sentences."""
        
        commit_prompt = f"""
        Analyze this NixOS git commit:
        
        **Commit Message:** {commit['message']}
        **Files Modified:** {', '.join(commit['changes']['files_modified'][:5])}
        
        **Key Changes in Diff:**
        {self.extract_key_changes(commit['diff'])}
        
        Provide a concise technical summary of what this commit accomplishes.
        """
        
        analysis = self.call_ollama(commit_prompt, system_prompt)
        return analysis or f"Modified {', '.join(commit['changes']['files_modified'][:3])}"
    
    def extract_key_changes(self, diff_content):
        """Extract most important lines from diff for AI analysis"""
        lines = diff_content.split('\n')
        key_lines = []
        
        for line in lines:
            # Include important additions/removals
            if line.startswith('+') or line.startswith('-'):
                # Skip file headers and minor changes
                if not any(skip in line for skip in ['+++', '---', '@@', 'index ']):
                    stripped = line[1:].strip()
                    if len(stripped) > 10:  # Ignore very short lines
                        key_lines.append(line)
                        
                if len(key_lines) >= 20:  # Limit to most important changes
                    break
        
        return '\n'.join(key_lines)
    
    def generate_system_evolution_narrative(self, commits):
        """Generate a narrative about system evolution"""
        
        system_prompt = """You are documenting the evolution of a NixOS homeserver system.
        Create a narrative summary showing how the system has grown and improved.
        Focus on major capabilities, architectural decisions, and system maturity.
        Write in a technical but engaging style. Maximum 4 sentences."""
        
        # Prepare commit summaries
        commit_summaries = []
        for commit in commits[:8]:  # Last 8 commits for context
            summary = f"- {commit['message']} (modified: {', '.join(commit['changes']['files_modified'][:2])})"
            commit_summaries.append(summary)
        
        evolution_prompt = f"""
        Based on these recent NixOS commits, write a narrative about how this homeserver system has evolved:
        
        {chr(10).join(commit_summaries)}
        
        Highlight key improvements in capabilities like containerization, GPU acceleration, monitoring, or storage management.
        """
        
        narrative = self.call_ollama(evolution_prompt, system_prompt)
        return narrative or "System continues to evolve with ongoing improvements to containerization and service management."
    
    def generate_technical_summary(self, commits):
        """Generate technical summary for system primer"""
        
        # Analyze changes by category
        categories = {
            'containers': [],
            'gpu': [],
            'monitoring': [],
            'storage': [],
            'security': [],
            'services': []
        }
        
        for commit in commits:
            changes = commit['changes']
            if changes['containers_added']:
                categories['containers'].extend(changes['containers_added'])
            if changes['gpu_changes']:
                categories['gpu'].append(commit['message'])
            if changes['monitoring_changes']:
                categories['monitoring'].append(commit['message'])
            if changes['storage_changes']:
                categories['storage'].append(commit['message'])
            if changes['security_changes']:
                categories['security'].append(commit['message'])
            if changes['services_added']:
                categories['services'].extend(changes['services_added'])
        
        system_prompt = """You are a NixOS system administrator creating status updates.
        Generate concise bullet points about recent system improvements.
        Be specific about technical capabilities added. Use appropriate emojis for categories.
        Maximum 6 bullet points."""
        
        summary_prompt = f"""
        Generate bullet points summarizing recent NixOS system improvements:
        
        **Containers Added:** {', '.join(set(categories['containers'])) or 'None'}
        **Services Added:** {', '.join(set(categories['services'])) or 'None'}
        **GPU Updates:** {len(categories['gpu'])} commits
        **Monitoring Updates:** {len(categories['monitoring'])} commits
        **Storage Updates:** {len(categories['storage'])} commits
        **Security Updates:** {len(categories['security'])} commits
        
        Format as markdown bullet points with emojis.
        """
        
        summary = self.call_ollama(summary_prompt, system_prompt)
        return summary or "- ✅ System continues operating with recent configuration updates"
    
    def update_documentation_with_ai(self, commits):
        """Update multiple documentation files with AI insights"""
        
        if not commits:
            print("No commits to analyze")
            return
            
        print(f"🤖 Analyzing {len(commits)} commits with Ollama AI...")
        
        # Test Ollama connection first
        if not self.test_ollama_connection():
            print("❌ Cannot connect to Ollama. Skipping AI analysis.")
            return
        
        # Generate AI-powered content
        evolution_narrative = self.generate_system_evolution_narrative(commits)
        technical_summary = self.generate_technical_summary(commits)
        
        # Update CLAUDE_CODE_SYSTEM_PRIMER.md
        self.update_system_primer(commits, evolution_narrative, technical_summary)
        
        # Update SYSTEM_CONCEPTS_AND_ARCHITECTURE.md
        self.update_architecture_docs(commits)
        
        print("✅ AI-enhanced documentation updated!")
    
    def update_system_primer(self, commits, evolution_narrative, technical_summary):
        """Update system primer with AI-generated content"""
        primer_path = self.docs_path / "CLAUDE_CODE_SYSTEM_PRIMER.md"
        if not primer_path.exists():
            print(f"⚠️ {primer_path} not found")
            return
            
        content = primer_path.read_text()
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M')
        
        # AI-generated recently completed section
        new_section = f"""### **Recently Completed** ✅ (AI-Generated: {timestamp})

**System Evolution Summary:**
{evolution_narrative}

**Recent Technical Improvements:**
{technical_summary}

**Latest Commits** (Last 7 days):
{self.format_commit_summaries(commits[:5])}"""
        
        # Replace the existing section
        pattern = r'### \*\*Recently Completed\*\* ✅.*?(?=### \*\*Known Issues\*\*|\Z)'
        content = re.sub(pattern, new_section + '\n\n', content, flags=re.DOTALL)
        
        primer_path.write_text(content)
        print(f"📝 Updated {primer_path.name} with AI insights")
    
    def format_commit_summaries(self, commits):
        """Format commits with AI analysis"""
        if not commits:
            return "- No recent changes"
            
        summaries = []
        for commit in commits:
            short_hash = commit['hash'][:8] if commit['hash'] else 'unknown'
            
            # Get AI analysis for this commit (with fallback)
            print(f"  🔍 Analyzing commit {short_hash}...")
            ai_summary = self.analyze_commit_with_ai(commit)
            
            summaries.append(f"- **{short_hash}**: {ai_summary}")
            
        return '\n'.join(summaries)
    
    def update_architecture_docs(self, commits):
        """Update architecture documentation with AI insights"""
        arch_path = self.docs_path / "SYSTEM_CONCEPTS_AND_ARCHITECTURE.md"
        if not arch_path.exists():
            print(f"⚠️ {arch_path} not found")
            return
            
        # Generate architectural insights
        system_prompt = """You are a systems architect documenting NixOS infrastructure.
        Analyze recent commits to identify architectural patterns and improvements.
        Maximum 3 sentences, focus on containerization, GPU integration, or service orchestration."""
        
        arch_prompt = f"""
        Based on these recent commits to a NixOS homeserver, identify significant architectural changes:
        
        {self.format_commits_for_analysis(commits[:5])}
        
        Write about architectural evolution, focusing on infrastructure improvements.
        """
        
        arch_insights = self.call_ollama(arch_prompt, system_prompt)
        
        if arch_insights:
            content = arch_path.read_text()
            timestamp = datetime.now().strftime('%Y-%m-%d')
            
            # Add AI insights to the overview
            ai_section = f"""
## Recent Architectural Evolution (AI-Generated: {timestamp})

{arch_insights}

---
"""
            
            # Insert after the overview section
            content = content.replace("## Table of Contents", ai_section + "## Table of Contents")
            arch_path.write_text(content)
            print(f"🏗️ Updated {arch_path.name} with architectural insights")
    
    def format_commits_for_analysis(self, commits):
        """Format commits for AI analysis"""
        formatted = []
        for commit in commits:
            formatted.append(f"- {commit['message']} (files: {', '.join(commit['changes']['files_modified'][:3])})")
        return '\n'.join(formatted)
    
    def parse_recent_changes(self, days=7):
        """Parse recent commits from changelog"""
        commits = []
        
        if not self.changelog_path.exists():
            print(f"⚠️ Changelog not found at {self.changelog_path}")
            return commits
            
        content = self.changelog_path.read_text()
        commit_sections = re.split(r'^## Commit:', content, flags=re.MULTILINE)[1:]
        
        for section in commit_sections[-10:]:  # Last 10 commits
            commit = self.parse_commit_section(section)
            if commit:
                commits.append(commit)
                
        print(f"📊 Parsed {len(commits)} commits from changelog")
        return commits
    
    def parse_commit_section(self, section):
        """Extract meaningful info from a commit section"""
        lines = section.split('\n')
        commit_hash = lines[0].strip()
        date_match = re.search(r'\*\*Date:\*\* (.+)', section)
        msg_match = re.search(r'\*\*Message:\*\* (.+)', section)
        diff_match = re.search(r'```diff\n(.*?)\n```', section, re.DOTALL)
        diff_content = diff_match.group(1) if diff_match else ""
        
        return {
            'hash': commit_hash,
            'date': date_match.group(1) if date_match else None,
            'message': msg_match.group(1) if msg_match else None,
            'diff': diff_content,
            'changes': self.analyze_diff(diff_content)
        }
    
    def analyze_diff(self, diff_content):
        """Analyze diff to understand what changed"""
        changes = {
            'files_modified': [],
            'services_added': [],
            'services_removed': [],
            'containers_added': [],
            'containers_removed': [],
            'gpu_changes': False,
            'monitoring_changes': False,
            'storage_changes': False,
            'security_changes': False
        }
        
        lines = diff_content.split('\n')
        current_file = None
        
        for line in lines:
            if line.startswith('+++') or line.startswith('---'):
                file_match = re.search(r'[+-]{3} [ab]/(.+)', line)
                if file_match:
                    current_file = file_match.group(1)
                    if current_file not in changes['files_modified']:
                        changes['files_modified'].append(current_file)
            
            if line.startswith('+'):
                self.detect_additions(line, changes, current_file)
            elif line.startswith('-'):
                self.detect_removals(line, changes, current_file)
                
        return changes
    
    def detect_additions(self, line, changes, current_file):
        """Detect what was added"""
        content = line[1:].strip()
        
        if 'virtualisation.oci-containers.containers' in content:
            container_match = re.search(r'containers\.(\w+)', content)
            if container_match:
                changes['containers_added'].append(container_match.group(1))
        elif 'services.' in content and 'enable = true' in content:
            service_match = re.search(r'services\.(\w+)', content)
            if service_match:
                changes['services_added'].append(service_match.group(1))
        elif any(gpu_term in content.lower() for gpu_term in ['nvidia', 'cuda', 'gpu', 'tensorrt']):
            changes['gpu_changes'] = True
        elif any(storage_term in content for storage_term in ['/mnt/hot', '/mnt/media', 'fileSystems']):
            changes['storage_changes'] = True
        elif any(sec_term in content for sec_term in ['sops.secrets', 'firewall', 'tailscale']):
            changes['security_changes'] = True
        elif any(mon_term in content for mon_term in ['prometheus', 'grafana', 'alertmanager']):
            changes['monitoring_changes'] = True
    
    def detect_removals(self, line, changes, current_file):
        """Detect what was removed"""
        content = line[1:].strip()
        if 'enable = true' in content and 'services.' in content:
            service_match = re.search(r'services\.(\w+)', content)
            if service_match:
                changes['services_removed'].append(service_match.group(1))

if __name__ == "__main__":
    generator = AIDocumentationGenerator()
    recent_commits = generator.parse_recent_changes(days=7)
    generator.update_documentation_with_ai(recent_commits)
```

---

## 🪝 **Git Post-Commit Hook**

**File:** `/etc/nixos/.git/hooks/post-commit`

```bash
#!/bin/bash
# Git Post-Commit Hook for AI Documentation System
# Captures commit diffs and triggers AI analysis

COMMIT_HASH=$(git rev-parse HEAD)
COMMIT_MSG=$(git log -1 --pretty=%B)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "📝 Capturing commit for AI documentation system..."

# Ensure changelog directory exists
mkdir -p /etc/nixos/docs

# Append to structured changelog
echo "
## Commit: $COMMIT_HASH
**Date:** $TIMESTAMP
**Message:** $COMMIT_MSG

\`\`\`diff
$(git show --no-merges --format="" $COMMIT_HASH)
\`\`\`

---
" >> /etc/nixos/docs/SYSTEM_CHANGELOG.md

echo "🤖 Triggering AI documentation generation..."

# Run AI documentation generator
python3 /etc/nixos/scripts/ai-narrative-docs.py 2>&1 | tee -a /etc/nixos/docs/ai-doc-generation.log

# Check if AI generation was successful
if [ $? -eq 0 ]; then
    echo "✅ AI documentation generation complete!"
    
    # Auto-commit documentation updates if any were made
    if git diff --quiet docs/; then
        echo "📄 No documentation changes to commit"
    else
        echo "📚 Auto-committing documentation updates..."
        git add docs/
        git commit -m "🤖 Auto-update documentation via AI analysis

Generated from commit: $COMMIT_HASH
Timestamp: $TIMESTAMP"
    fi
else
    echo "⚠️ AI documentation generation failed - check ai-doc-generation.log"
fi

echo "✅ Post-commit processing complete!"
```

---

## 📊 **Initial System Changelog**

**File:** `/etc/nixos/docs/SYSTEM_CHANGELOG.md`

```markdown
# System Changelog - hwc-server

**Purpose:** Structured log of all git commits for AI analysis  
**Generated:** Automatically via post-commit hook  
**AI Model:** Ollama (llama3.2:3b) running locally with CUDA acceleration

---

## Initial Setup
**Date:** 2025-08-05
**Message:** AI Documentation System Implementation

This changelog captures all future commits for intelligent documentation generation.

---
```

---

## 🔧 **Enhanced grebuild Function**

Add to your shell configuration (`~/.zshrc` or equivalent):

```bash
grebuild() {
    local message="$1"
    
    if [ -z "$message" ]; then
        echo "❌ Usage: grebuild 'commit message'"
        echo "📖 This will test, commit, generate AI docs, and rebuild"
        return 1
    fi
    
    echo "🧪 Testing NixOS configuration..."
    sudo nixos-rebuild test --flake .#hwc-server || {
        echo "❌ Configuration test failed!"
        return 1
    }
    
    echo "💾 Committing changes..."
    sudo git add .
    sudo git commit -m "$message" || {
        echo "❌ Git commit failed!"
        return 1
    }
    
    echo "🤖 AI documentation generation triggered by post-commit hook..."
    sleep 2  # Give the hook time to complete
    
    echo "🚀 Applying NixOS configuration..."
    sudo nixos-rebuild switch --flake .#hwc-server || {
        echo "❌ NixOS rebuild failed!"
        echo "🔄 Configuration was committed but not applied"
        return 1
    }
    
    echo ""
    echo "✅ System updated successfully with AI-generated documentation!"
    echo "📖 Check /etc/nixos/docs/ for updated documentation"
    echo "📊 View changelog: /etc/nixos/docs/SYSTEM_CHANGELOG.md"
    echo "🤖 AI logs: /etc/nixos/docs/ai-doc-generation.log"
}

# Alias for convenience
alias gb='grebuild'
```

---

## 🧪 **Testing Procedure**

### **Step 1: Basic Connectivity Test**
```bash
# Test Ollama is running
curl http://localhost:11434/api/tags

# Test AI script directly
python3 /etc/nixos/scripts/ai-narrative-docs.py
```

### **Step 2: End-to-End Test**
```bash
# Make a small test change
echo "# Test comment" >> /etc/nixos/test.txt

# Test the full pipeline
grebuild "Test AI documentation system implementation"

# Verify outputs
cat /etc/nixos/docs/SYSTEM_CHANGELOG.md
cat /etc/nixos/docs/CLAUDE_CODE_SYSTEM_PRIMER.md
```

### **Step 3: Validation Checks**
- [ ] Changelog contains structured commit data
- [ ] AI analysis appears in system primer
- [ ] No errors in `/etc/nixos/docs/ai-doc-generation.log`
- [ ] Git history shows auto-documentation commits

---

## 🔒 **Rollback Procedures**

### **If Implementation Fails:**

```bash
# 1. Disable the post-commit hook
sudo chmod -x /etc/nixos/.git/hooks/post-commit

# 2. Revert to previous grebuild function
# (Remove the enhanced version from shell config)

# 3. Remove AI system files if needed
sudo rm -f /etc/nixos/scripts/ai-narrative-docs.py
sudo rm -f /etc/nixos/docs/SYSTEM_CHANGELOG.md
sudo rm -f /etc/nixos/docs/ai-doc-generation.log

# 4. Clean up any auto-commit documentation
git log --oneline | grep "🤖 Auto-update documentation"
# If found, consider git revert of those commits
```

### **If AI Generation Fails:**
- System will continue working normally
- Only AI-enhanced documentation will be missing
- Standard git workflow and manual documentation remain intact
- Check `/etc/nixos/docs/ai-doc-generation.log` for errors

### **If Ollama Issues:**
- Verify Ollama service: `systemctl status ollama`
- Check model availability: `ollama list`
- Test model: `ollama run llama3.2:3b "test"`
- AI script will gracefully fail if Ollama unavailable

---

## 🔧 **File Permissions Setup**

```bash
# Scripts directory
sudo mkdir -p /etc/nixos/scripts
sudo chmod 755 /etc/nixos/scripts

# AI generator script
sudo chmod +x /etc/nixos/scripts/ai-narrative-docs.py

# Git hook
sudo chmod +x /etc/nixos/.git/hooks/post-commit

# Docs directory (if not exists)
sudo mkdir -p /etc/nixos/docs
sudo chmod 755 /etc/nixos/docs

# Log file permissions
sudo touch /etc/nixos/docs/ai-doc-generation.log
sudo chmod 644 /etc/nixos/docs/ai-doc-generation.log
```

---

## 📈 **Expected Benefits**

1. **Automatic Documentation**: Every commit generates intelligent documentation
2. **System Evolution Tracking**: AI identifies patterns and improvements over time
3. **Context-Aware Updates**: Documentation reflects actual system capabilities
4. **Local AI Processing**: Fast, private analysis using your GPU-accelerated Ollama
5. **Zero Maintenance**: Once set up, runs automatically forever
6. **Rollback Safety**: Can be disabled/removed without affecting core system

---

## 🚨 **Important Notes**

- **Ollama Dependency**: System requires Ollama to be running for AI features
- **Model Requirements**: Uses llama3.2:3b (fast, good for technical text)
- **GPU Acceleration**: Leverages your NVIDIA Quadro P1000 for AI processing
- **Git Integration**: Hooks into every commit automatically
- **Backup Strategy**: Always test with small commits first
- **Monitoring**: Check `/etc/nixos/docs/ai-doc-generation.log` for issues

---

## 🔄 **Maintenance**

- **Monthly**: Review AI-generated documentation for accuracy
- **As Needed**: Update Ollama model if better ones become available
- **Quarterly**: Clean up old changelog entries if file becomes too large
- **On Issues**: Check Ollama service and model availability

---

**End of Implementation Plan**

This document provides complete instructions for implementing and maintaining the AI-enhanced documentation system. Keep this file as reference for troubleshooting and future maintenance.