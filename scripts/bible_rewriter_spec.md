# AI Bible Rewriting Engine - Technical Specification

## 🎯 Overview

The AI Bible Rewriting Engine is responsible for intelligently updating bible documentation files by integrating accumulated changes while preserving existing valuable content, maintaining technical accuracy, and ensuring consistency with the system's current state.

## 🏗️ System Architecture

### Core Components
1. **Change Integration Engine**: Processes accumulated changes and determines update strategy
2. **Bible-Specific Prompt System**: Specialized AI prompts tailored to each bible's domain
3. **Content Preservation Manager**: Protects valuable existing content during rewrites
4. **Consistency Validation System**: Ensures technical accuracy and cross-bible consistency
5. **Backup & Versioning Manager**: Creates safe rollback points and change history

### Integration Points
- **Input**: Change accumulation logs from `change_accumulator.py`
- **Trigger**: Threshold detection from `threshold_manager.py`
- **Output**: Updated bible files with integrated changes
- **Validation**: Cross-bible consistency checks via `consistency_manager.py`

## 📋 Functional Requirements

### Primary Functions
1. **Intelligent Change Integration**: Merge accumulated changes into existing bible content without losing valuable information
2. **Context-Aware Rewriting**: Understand the technical context of changes and their system impact
3. **Content Preservation**: Identify and protect critical existing content that shouldn't be modified
4. **Technical Accuracy**: Maintain technical precision and system-specific knowledge
5. **Cross-Reference Maintenance**: Update cross-bible references when related content changes

### Secondary Functions
1. **Quality Assessment**: Evaluate the quality of AI-generated updates
2. **Conflict Resolution**: Handle conflicting information between old and new content
3. **Formatting Consistency**: Maintain consistent documentation formatting and structure
4. **Change Documentation**: Document what changes were made and why

## 🔧 Technical Specifications

### Bible-Specific AI Prompting Strategy

#### Hardware & GPU Bible Prompts
**Domain Expertise Required**: NVIDIA Pascal architecture, GPU device access patterns, container GPU sharing
**Key Preservation Areas**: GPU device paths, driver compatibility, Pascal-specific limitations
**Update Focus**: New GPU-accelerated services, performance optimizations, hardware changes

```python
HARDWARE_GPU_PROMPT_TEMPLATE = """
You are a technical documentation expert specializing in NVIDIA GPU acceleration for containerized services on NixOS.

CRITICAL CONTEXT:
- System: NixOS homeserver with NVIDIA Quadro P1000 (Pascal architecture, 4GB VRAM)  
- Container Runtime: Podman with systemd integration
- GPU Sharing: Multiple services share GPU through device access patterns
- Architecture Constraints: Pascal requires USE_FP16=false for TensorRT

ACCUMULATED CHANGES TO INTEGRATE:
{accumulated_changes}

EXISTING BIBLE CONTENT:
{existing_content}

INTEGRATION REQUIREMENTS:
1. Preserve exact GPU device access patterns and environment variables
2. Maintain Pascal architecture limitations and workarounds  
3. Update service GPU utilization matrix with new services
4. Preserve performance benchmarks and optimization guidelines
5. Update cross-references to container services that use GPU

TECHNICAL ACCURACY REQUIREMENTS:
- GPU device paths must match actual hardware configuration
- Container GPU options must be syntactically correct for Podman
- Pascal compute capability (6.1) constraints must be preserved
- Memory limitations (4GB VRAM) must be considered in recommendations

Generate an updated Hardware & GPU Bible that integrates the accumulated changes while preserving all critical technical content and maintaining accuracy for the specific hardware configuration.
"""
```

#### Container Services Bible Prompts  
**Domain Expertise Required**: Podman containers, systemd services, media pipeline architecture, network configuration
**Key Preservation Areas**: Service configurations, network topology, resource limits
**Update Focus**: New services, configuration changes, optimization improvements

```python
CONTAINER_SERVICES_PROMPT_TEMPLATE = """
You are a technical documentation expert specializing in containerized service orchestration using Podman and systemd on NixOS.

CRITICAL CONTEXT:
- Container Runtime: Podman with systemd service integration
- Network Architecture: Custom media-network with service isolation
- Service Categories: Media (*arr apps), Surveillance (Frigate), Business (dashboards), AI (Ollama)
- Resource Sharing: GPU access, storage tiers, network connectivity

ACCUMULATED CHANGES TO INTEGRATE:
{accumulated_changes}

EXISTING BIBLE CONTENT:
{existing_content}

INTEGRATION REQUIREMENTS:
1. Preserve exact container configurations and systemd service definitions
2. Maintain network topology and inter-service communication patterns
3. Update service dependency maps and startup sequences
4. Preserve resource limits and optimization settings
5. Update cross-references to GPU, storage, and monitoring configurations

TECHNICAL ACCURACY REQUIREMENTS:
- Container names must match actual systemd service names
- Network configurations must be valid for Podman networking
- Resource limits must be appropriate for system capabilities
- Port mappings must avoid conflicts and match firewall rules
- Environment variables must match actual service requirements

Generate an updated Container Services & Orchestration Bible that integrates the accumulated changes while preserving all service configurations and maintaining technical accuracy.
"""
```

#### Storage & Data Pipeline Bible Prompts
**Domain Expertise Required**: Two-tier storage architecture, automated data migration, backup strategies
**Key Preservation Areas**: Storage paths, automation scripts, retention policies
**Update Focus**: New data flows, storage optimization, automation improvements

```python
STORAGE_DATA_PROMPT_TEMPLATE = """
You are a technical documentation expert specializing in two-tier storage architectures and automated data pipeline management.

CRITICAL CONTEXT:
- Architecture: Hot storage (SSD /mnt/hot) + Cold storage (HDD /mnt/media)
- Data Flow: Download → Process → Migrate → Archive
- Automation: Automated migration based on completion status, age, and thresholds
- Services: Integration with media pipeline, surveillance, and business services

ACCUMULATED CHANGES TO INTEGRATE:
{accumulated_changes}

EXISTING BIBLE CONTENT:
{existing_content}

INTEGRATION REQUIREMENTS:
1. Preserve exact storage paths and mount configurations
2. Maintain data flow diagrams and automation workflows
3. Update capacity planning and storage usage patterns
4. Preserve backup strategies and disaster recovery procedures
5. Update cross-references to services that use storage tiers

TECHNICAL ACCURACY REQUIREMENTS:
- Storage paths must match actual filesystem mounts
- Automation scripts must be syntactically correct
- Retention policies must be mathematically sound
- Capacity calculations must reflect actual storage hardware
- Data flow timing must be realistic for storage performance

Generate an updated Storage & Data Pipeline Bible that integrates the accumulated changes while preserving all storage configurations and automation workflows.
"""
```

#### Monitoring & Observability Bible Prompts
**Domain Expertise Required**: Prometheus metrics, Grafana dashboards, alerting systems, system diagnostics
**Key Preservation Areas**: Metric definitions, dashboard configurations, alert thresholds
**Update Focus**: New metrics, dashboard improvements, alert refinements

```python
MONITORING_OBSERVABILITY_PROMPT_TEMPLATE = """
You are a technical documentation expert specializing in comprehensive system monitoring using Prometheus, Grafana, and custom monitoring solutions.

CRITICAL CONTEXT:
- Metrics Platform: Prometheus with custom exporters
- Visualization: Grafana with provisioned dashboards  
- Alerting: Alert management with webhook notifications
- Scope: System, container, GPU, storage, and application metrics

ACCUMULATED CHANGES TO INTEGRATE:
{accumulated_changes}

EXISTING BIBLE CONTENT:
{existing_content}

INTEGRATION REQUIREMENTS:
1. Preserve exact metric names and collection configurations
2. Maintain dashboard JSON structures and visualization settings
3. Update alert rules and notification configurations
4. Preserve diagnostic procedures and troubleshooting workflows
5. Update cross-references to monitored services and systems

TECHNICAL ACCURACY REQUIREMENTS:
- Metric names must match actual Prometheus exports
- Grafana queries must be syntactically correct for the data source
- Alert thresholds must be appropriate for system capabilities
- Dashboard panels must reference existing metrics
- Diagnostic commands must work on the actual system

Generate an updated Monitoring & Observability Bible that integrates the accumulated changes while preserving all monitoring configurations and diagnostic procedures.
"""
```

#### AI Documentation Bible Prompts
**Domain Expertise Required**: Local Ollama operation, AI documentation workflows, prompt engineering
**Key Preservation Areas**: AI model configurations, workflow automation, troubleshooting procedures
**Update Focus**: AI system improvements, new automation features, prompt optimizations

```python
AI_DOCUMENTATION_PROMPT_TEMPLATE = """
You are a technical documentation expert specializing in AI-powered documentation systems using local Ollama models for automated analysis and generation.

CRITICAL CONTEXT:
- AI Platform: Local Ollama with llama3.2:3b model
- Integration: Post-successful-build triggers with change accumulation
- Workflow: Git changes → Change analysis → Threshold detection → Bible updates
- Error Handling: Robust error recovery and process locking

ACCUMULATED CHANGES TO INTEGRATE:
{accumulated_changes}

EXISTING BIBLE CONTENT:
{existing_content}

INTEGRATION REQUIREMENTS:
1. Preserve exact AI model configurations and API endpoints
2. Maintain workflow automation and trigger mechanisms
3. Update prompt templates and AI processing logic
4. Preserve error handling and recovery procedures
5. Update cross-references to system integration points

TECHNICAL ACCURACY REQUIREMENTS:
- Ollama API calls must match actual model capabilities
- Workflow scripts must be executable on the target system
- Prompt engineering must be effective for llama3.2:3b model
- Error handling must cover actual failure scenarios
- Integration points must match actual system architecture

Generate an updated AI Documentation & Automation Bible that integrates the accumulated changes while preserving all AI system configurations and automation workflows.
"""
```

#### System Architecture Bible Prompts
**Domain Expertise Required**: NixOS configuration, system security, deployment procedures, architectural decisions
**Key Preservation Areas**: NixOS configurations, security settings, deployment procedures
**Update Focus**: Architectural changes, security updates, operational improvements

```python
SYSTEM_ARCHITECTURE_PROMPT_TEMPLATE = """
You are a technical documentation expert specializing in NixOS system architecture, security configuration, and operational procedures for complex homelab environments.

CRITICAL CONTEXT:
- Platform: NixOS with Flakes, declarative configuration management
- Security: SOPS secrets, Tailscale VPN, ProtonVPN via Gluetun, firewall configuration
- Deployment: Git-based configuration with automated rebuilds
- Architecture: Homeserver with GPU acceleration, containerization, two-tier storage

ACCUMULATED CHANGES TO INTEGRATE:
{accumulated_changes}

EXISTING BIBLE CONTENT:
{existing_content}

INTEGRATION REQUIREMENTS:
1. Preserve exact NixOS configuration patterns and deployment procedures
2. Maintain security configurations and access control settings
3. Update architectural diagrams and system relationships
4. Preserve operational procedures and troubleshooting workflows
5. Update cross-references to all other system components

TECHNICAL ACCURACY REQUIREMENTS:
- NixOS configurations must be syntactically correct
- Security settings must follow NixOS and security best practices
- Deployment procedures must work with the actual system setup
- Architectural descriptions must match actual system implementation
- Cross-references must accurately reflect system relationships

Generate an updated System Architecture & Operations Bible that integrates the accumulated changes while preserving all system configurations and operational procedures.
"""
```

### Content Preservation Strategy

#### Critical Content Identification
```python
PRESERVATION_PATTERNS = {
    "exact_commands": [
        r"```bash\n.*?\n```",
        r"`[^`]+`",
        r"sudo [^\\n]+"
    ],
    "configuration_blocks": [
        r"```(?:yaml|json|toml|nix).*?```",
        r"```\n(?:.*?=.*?\n)+```"
    ],
    "technical_specifications": [
        r"- \*\*[^*]+\*\*: [^\\n]+",
        r"\| [^|]+ \| [^|]+ \|",
        r"NVIDIA.*?P1000.*?Pascal"
    ],
    "file_paths": [
        r"/[a-zA-Z0-9/_.-]+",
        r"`/[^`]+`"
    ],
    "service_names": [
        r"podman-[a-zA-Z0-9-]+\.service",
        r"systemd.*?\.service"
    ]
}
```

#### Change Integration Logic
```python
def integrate_changes(existing_content, accumulated_changes, bible_type):
    """
    Intelligently integrate accumulated changes into existing bible content
    """
    preserved_content = extract_critical_content(existing_content, bible_type)
    change_analysis = analyze_change_impact(accumulated_changes, bible_type)
    integration_strategy = determine_integration_approach(change_analysis)
    
    updated_content = apply_ai_rewriting(
        existing_content=existing_content,
        changes=accumulated_changes,
        preserved_content=preserved_content,
        strategy=integration_strategy,
        bible_type=bible_type
    )
    
    validated_content = validate_technical_accuracy(updated_content, bible_type)
    return validated_content
```

### Quality Assessment Framework

#### Technical Accuracy Validation
```python
VALIDATION_CHECKS = {
    "hardware_gpu": [
        "nvidia_device_paths_valid",
        "pascal_limitations_preserved", 
        "gpu_memory_constraints_accurate",
        "container_gpu_options_syntactically_correct"
    ],
    "container_services": [
        "service_names_match_systemd",
        "network_configurations_valid",
        "resource_limits_appropriate",
        "port_mappings_conflict_free"
    ],
    "storage_data": [
        "storage_paths_exist",
        "automation_scripts_executable",
        "capacity_calculations_accurate",
        "retention_policies_mathematically_sound"
    ],
    "monitoring_observability": [
        "metric_names_match_prometheus",
        "grafana_queries_syntactically_correct",
        "alert_thresholds_reasonable",
        "diagnostic_commands_functional"
    ],
    "ai_documentation": [
        "ollama_api_calls_valid",
        "model_capabilities_accurate",
        "workflow_scripts_executable",
        "error_handling_comprehensive"
    ],
    "system_architecture": [
        "nixos_configurations_valid",
        "security_settings_best_practices",
        "deployment_procedures_functional",
        "cross_references_accurate"
    ]
}
```

## 🔐 Error Handling & Recovery

### Rewriting Failure Recovery
```python
class BibleRewritingError(Exception):
    """Custom exception for bible rewriting failures"""
    pass

def safe_bible_rewrite(bible_name, changes, existing_content):
    """
    Safely rewrite bible with comprehensive error handling
    """
    backup_path = create_bible_backup(bible_name)
    
    try:
        updated_content = perform_ai_rewrite(bible_name, changes, existing_content)
        validate_rewrite_quality(updated_content, bible_name)
        return updated_content
        
    except AIModelError as e:
        log_error(f"AI model failed for {bible_name}: {e}")
        restore_from_backup(bible_name, backup_path)
        raise BibleRewritingError(f"AI rewriting failed: {e}")
        
    except ValidationError as e:
        log_error(f"Validation failed for {bible_name}: {e}")
        restore_from_backup(bible_name, backup_path) 
        raise BibleRewritingError(f"Content validation failed: {e}")
        
    except Exception as e:
        log_error(f"Unexpected error rewriting {bible_name}: {e}")
        restore_from_backup(bible_name, backup_path)
        raise BibleRewritingError(f"Unexpected rewriting error: {e}")
```

### Rollback Mechanisms
```python
def create_bible_backup(bible_name):
    """Create timestamped backup of bible before rewriting"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"/etc/nixos/docs/bibles/backups/{bible_name}_{timestamp}.md"
    
    original_path = f"/etc/nixos/docs/bibles/{bible_name}.md"
    shutil.copy2(original_path, backup_path)
    
    return backup_path

def restore_from_backup(bible_name, backup_path):
    """Restore bible from backup in case of rewriting failure"""
    original_path = f"/etc/nixos/docs/bibles/{bible_name}.md"
    shutil.copy2(backup_path, original_path)
    
    log_info(f"Restored {bible_name} from backup: {backup_path}")
```

## 📊 Performance Requirements

### Rewriting Performance Targets
- **Single Bible Rewrite**: < 2 minutes per bible
- **Multiple Bible Updates**: < 5 minutes for all affected bibles
- **Memory Usage**: < 1GB RAM during rewriting process
- **Disk Usage**: Backups limited to 10 versions per bible

### AI Model Optimization
- **Context Window**: Optimize for llama3.2:3b's 4K context window
- **Temperature Settings**: Low temperature (0.2-0.3) for consistent technical writing
- **Prompt Engineering**: Minimize tokens while maximizing context
- **Response Processing**: Stream processing for large bible rewrites

## 🔗 Integration Interfaces

### Input Interface (from Change Accumulator)
```python
class ChangeAccumulation:
    def __init__(self):
        self.bible_category: str
        self.changes: List[ChangeRecord]
        self.significance_score: float
        self.change_types: List[str]
        self.affected_sections: List[str]
        
class ChangeRecord:
    def __init__(self):
        self.timestamp: datetime
        self.change_type: str  # "add", "modify", "delete", "rename"
        self.file_path: str
        self.description: str
        self.diff: str
        self.significance: float
```

### Output Interface (to Bible Files)
```python
class BibleUpdateResult:
    def __init__(self):
        self.bible_name: str
        self.update_success: bool
        self.changes_integrated: int
        self.content_preserved: List[str]
        self.validation_results: Dict[str, bool]
        self.backup_path: str
        self.update_duration: float
        self.ai_tokens_used: int
```

### Validation Interface (to Consistency Manager)
```python
class BibleValidationRequest:
    def __init__(self):
        self.updated_bible: str
        self.dependent_bibles: List[str]
        self.consistency_rules: Dict[str, str]
        self.cross_references: List[str]
```

## 📋 Implementation Phases

### Phase 1: Core Rewriting Engine
- Implement basic AI rewriting functionality
- Create bible-specific prompt templates  
- Build content preservation system
- Add basic error handling and backups

### Phase 2: Quality & Validation
- Implement technical accuracy validation
- Add quality assessment framework
- Create comprehensive error recovery
- Build performance monitoring

### Phase 3: Advanced Features
- Add cross-bible consistency integration
- Implement change impact analysis
- Create rewriting optimization
- Add comprehensive logging and metrics

## 🎯 Success Criteria

### Functional Success
- **Content Preservation**: 100% preservation of critical technical content
- **Change Integration**: 95% successful integration of valid accumulated changes
- **Technical Accuracy**: 98% accuracy in technical configurations and commands
- **Cross-Reference Consistency**: 100% accuracy in cross-bible references

### Performance Success
- **Rewriting Speed**: Meet performance targets for bible update times
- **Resource Usage**: Stay within memory and disk usage limits
- **Error Recovery**: 100% successful recovery from rewriting failures
- **Quality Assessment**: Automated detection of quality issues

### Operational Success
- **Reliability**: 99% uptime for bible rewriting functionality
- **Monitoring**: Comprehensive logging and metrics for troubleshooting
- **Maintenance**: Minimal manual intervention required
- **Evolution**: System adapts to new bible types and content patterns

---

**Document Version**: 1.0
**Created**: 2025-08-06  
**Component**: AI Bible Rewriting Engine
**Integration**: Core component of Bible Documentation System