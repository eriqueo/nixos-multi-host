{ config, lib, pkgs, ... }:

let
  cfg = config.my.ai.transcriptBatchControllerSafe;
  appRoot = "${config.xdg.dataHome}/transcript-batch-controller-safe";
  scriptPath = "${appRoot}/batch_controller_safe.py";
in
{
  options.my.ai.transcriptBatchControllerSafe = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
  };

  config = lib.mkIf cfg.enable {
    home.activation.transcriptBatchControllerSafeDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${appRoot}
    '';

    home.file."${scriptPath}" = {
      executable = true;
      text = ''
#!/usr/bin/env python3
"""
Thermal-Safe Transcript Batch Controller - Safe overnight processing with temperature monitoring
"""
import json, os, sys, time, argparse, threading, queue, subprocess
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
import concurrent.futures
import re

class ContentType(Enum):
    BUSINESS = "business"
    TECHNICAL = "technical"
    EDUCATIONAL = "educational"
    ARCHIVE = "archive"
    UNKNOWN = "unknown"

class Priority(Enum):
    HIGH = 1
    MEDIUM = 2
    LOW = 3
    BACKGROUND = 4

class ProcessingStatus(Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress" 
    COMPLETED = "completed"
    FAILED = "failed"
    SKIPPED = "skipped"
    THERMAL_PAUSED = "thermal_paused"

class ThermalState(Enum):
    SAFE = "safe"
    WARNING = "warning"
    CRITICAL = "critical"
    COOLING = "cooling"

@dataclass
class FileJob:
    file_path: Path
    output_path: Path
    content_type: ContentType
    priority: Priority
    size_chars: int
    estimated_time: float
    status: ProcessingStatus = ProcessingStatus.PENDING
    attempts: int = 0
    error_message: str = ""
    processing_start: Optional[datetime] = None
    processing_end: Optional[datetime] = None
    
class ThermalManager:
    """Manages thermal monitoring and safety controls."""
    
    def __init__(self, temp_threshold_pause: float = 75.0, temp_threshold_resume: float = 65.0):
        self.temp_threshold_pause = temp_threshold_pause
        self.temp_threshold_resume = temp_threshold_resume
        self.thermal_state = ThermalState.SAFE
        self.last_temp_check = 0
        self.temp_check_interval = 30  # Check every 30 seconds
        self.cooling_start_time = None
        
    def get_cpu_temperature(self) -> float:
        """Get current CPU temperature from sensors."""
        try:
            result = subprocess.run(['sensors'], capture_output=True, text=True, timeout=10)
            if result.returncode != 0:
                return 0.0
                
            lines = result.stdout.split('\n')
            for line in lines:
                # Look for Package temperature (most representative)
                if 'Package id 0:' in line:
                    temp_match = re.search(r'\+(\d+\.\d+)°C', line)
                    if temp_match:
                        return float(temp_match.group(1))
                # Fallback to CPU temperature
                elif 'CPU:' in line and '°C' in line:
                    temp_match = re.search(r'\+(\d+\.\d+)°C', line)
                    if temp_match:
                        return float(temp_match.group(1))
        except Exception as e:
            print(f"⚠️ Temperature monitoring error: {e}")
            return 0.0
        
        return 0.0
    
    def check_thermal_status(self) -> Tuple[ThermalState, float]:
        """Check current thermal status and return state and temperature."""
        current_time = time.time()
        
        # Rate limit temperature checks
        if current_time - self.last_temp_check < self.temp_check_interval:
            return self.thermal_state, 0.0
            
        temperature = self.get_cpu_temperature()
        self.last_temp_check = current_time
        
        if temperature == 0.0:
            # If we can't read temperature, assume safe but warn
            print("⚠️ Cannot read temperature sensors, assuming safe operation")
            return ThermalState.SAFE, 0.0
        
        # Determine thermal state
        if temperature >= self.temp_threshold_pause:
            if self.thermal_state != ThermalState.CRITICAL:
                print(f"🌡️ Critical temperature detected: {temperature:.1f}°C - Pausing processing")
                self.thermal_state = ThermalState.CRITICAL
                self.cooling_start_time = current_time
        elif temperature <= self.temp_threshold_resume:
            if self.thermal_state in [ThermalState.CRITICAL, ThermalState.COOLING]:
                if self.cooling_start_time and (current_time - self.cooling_start_time) > 120:  # 2 min cooling
                    print(f"❄️ Temperature cooled to {temperature:.1f}°C - Resuming processing")
                    self.thermal_state = ThermalState.SAFE
                    self.cooling_start_time = None
                else:
                    self.thermal_state = ThermalState.COOLING
        elif temperature > self.temp_threshold_resume and temperature < self.temp_threshold_pause:
            if self.thermal_state == ThermalState.CRITICAL:
                self.thermal_state = ThermalState.COOLING
            elif self.thermal_state == ThermalState.SAFE:
                self.thermal_state = ThermalState.WARNING if temperature > 70 else ThermalState.SAFE
        
        return self.thermal_state, temperature
    
    def wait_for_thermal_safety(self) -> bool:
        """Wait until thermal conditions are safe for processing."""
        while True:
            state, temp = self.check_thermal_status()
            
            if state == ThermalState.SAFE:
                return True
            elif state in [ThermalState.CRITICAL, ThermalState.COOLING]:
                if temp > 0:
                    print(f"🌡️ Waiting for cooling: {temp:.1f}°C (target: {self.temp_threshold_resume:.1f}°C)")
                else:
                    print("🌡️ Thermal monitoring - waiting for safe conditions")
                time.sleep(60)  # Check every minute when overheated
            elif state == ThermalState.WARNING:
                print(f"⚠️ Elevated temperature: {temp:.1f}°C - Processing with caution")
                return True

class ContentClassifier:
    """Intelligent content classification for optimal processing routing."""
    
    def __init__(self):
        self.business_keywords = [
            'webinar', 'business', 'entrepreneur', 'systems', 'revenue', 'profit',
            'marketing', 'sales', 'clients', 'customers', 'scaling', 'growth'
        ]
        self.technical_keywords = [
            'tutorial', 'blender', 'modeling', 'architectural', 'cad', 'software',
            'tool', 'workflow', 'technique', 'step-by-step', 'how-to'
        ]
        self.educational_keywords = [
            'learning', 'guide', 'introduction', 'beginner', 'course', 'lesson',
            'teaching', 'explain', 'understand', 'fundamentals'
        ]
        
    def classify_content(self, file_path: Path) -> Tuple[ContentType, Priority]:
        """Analyze file and determine content type and processing priority."""
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            file_name = file_path.name.lower()
            
            # Check file path patterns
            path_str = str(file_path).lower()
            
            if 'jobtread' in path_str or 'jt ' in file_name:
                return ContentType.BUSINESS, Priority.HIGH
                
            if 'blender' in path_str or 'architectural' in path_str:
                return ContentType.TECHNICAL, Priority.MEDIUM
                
            if 'individual' in path_str and '2025-08' in path_str:
                return ContentType.ARCHIVE, Priority.LOW
                
            # Content-based classification
            content_lower = content.lower()
            
            business_score = sum(1 for kw in self.business_keywords if kw in content_lower)
            technical_score = sum(1 for kw in self.technical_keywords if kw in content_lower)
            educational_score = sum(1 for kw in self.educational_keywords if kw in content_lower)
            
            scores = {
                ContentType.BUSINESS: business_score,
                ContentType.TECHNICAL: technical_score,
                ContentType.EDUCATIONAL: educational_score
            }
            
            # Determine content type
            max_score = max(scores.values())
            if max_score == 0:
                content_type = ContentType.UNKNOWN
                priority = Priority.BACKGROUND
            else:
                content_type = max(scores.items(), key=lambda x: x[1])[0]
                
                # Assign priority based on type and score
                if content_type == ContentType.BUSINESS and business_score >= 3:
                    priority = Priority.HIGH
                elif content_type == ContentType.TECHNICAL and technical_score >= 2:
                    priority = Priority.MEDIUM
                elif content_type == ContentType.EDUCATIONAL:
                    priority = Priority.MEDIUM
                else:
                    priority = Priority.LOW
                    
            return content_type, priority
            
        except Exception as e:
            print(f"⚠️ Classification failed for {file_path}: {e}")
            return ContentType.UNKNOWN, Priority.BACKGROUND

class SafeBatchController:
    """Main thermal-safe batch processing controller."""
    
    def __init__(self, config_path: Optional[Path] = None):
        self.config_path = config_path or Path.home() / '.config' / 'transcript-batch-controller-safe.json'
        self.classifier = ContentClassifier()
        self.thermal_manager = ThermalManager()
        self.job_queue = queue.PriorityQueue()
        self.active_jobs = {}
        self.completed_jobs = []
        self.failed_jobs = []
        self.thermal_paused_jobs = []
        self.stats = {
            'total_files': 0,
            'completed_files': 0,
            'failed_files': 0,
            'thermal_pauses': 0,
            'processing_time': 0,
            'start_time': None,
            'estimated_completion': None
        }
        self.config = self.load_config()
        
    def load_config(self) -> Dict[str, Any]:
        """Load thermal-safe batch controller configuration."""
        default_config = {
            'max_workers': 1,  # Single worker for thermal safety
            'retry_attempts': 2,
            'timeout_multiplier': 2.5,  # More generous timeouts
            'processing_tools': {
                'enhanced': 'enhanced-transcript-formatter',
                'basic': 'transcript-formatter'
            },
            'inter_file_delay': 30,  # 30 second delay between files
            'thermal_check_interval': 30,  # Check temperature every 30s
            'temp_threshold_pause': 75.0,  # Pause at 75°C
            'temp_threshold_resume': 65.0,  # Resume at 65°C
            'max_processing_time_hours': 12  # Maximum 12 hour sessions
        }
        
        try:
            if self.config_path.exists():
                with open(self.config_path, 'r') as f:
                    user_config = json.load(f)
                    default_config.update(user_config)
        except Exception as e:
            print(f"⚠️ Config load error: {e}")
            
        # Update thermal manager with config
        self.thermal_manager.temp_threshold_pause = default_config['temp_threshold_pause']
        self.thermal_manager.temp_threshold_resume = default_config['temp_threshold_resume']
        
        return default_config
    
    def save_config(self):
        """Save current configuration."""
        try:
            self.config_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"⚠️ Config save error: {e}")
    
    def discover_files(self, input_dir: Path, pattern: str = "*.md") -> List[Path]:
        """Discover all transcript files in directory tree."""
        files = []
        
        if input_dir.is_file():
            files.append(input_dir)
        else:
            # Recursively find all matching files
            files.extend(input_dir.rglob(pattern))
            
        # Filter out non-transcript files
        transcript_files = []
        for file_path in files:
            if file_path.is_file() and file_path.suffix == '.md':
                # Skip README and other non-transcript files
                if file_path.name.lower() in ['readme.md', 'index.md']:
                    continue
                transcript_files.append(file_path)
                
        return sorted(transcript_files)
        
    def estimate_processing_time(self, file_path: Path) -> float:
        """Estimate AI processing time based on file size and chunking requirements."""
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            char_count = len(content)
            
            # AI processing time: ~20-25 seconds per 3000-character chunk (conservative for thermal safety)
            chunk_size = 3000
            num_chunks = max(1, (char_count + chunk_size - 1) // chunk_size)
            
            # Base processing time per chunk (more conservative for thermal safety)
            seconds_per_chunk = 25  # Slightly slower estimates for thermal safety
            base_time = num_chunks * seconds_per_chunk
            
            # Small file minimum (model loading overhead)
            if char_count < 5000:
                base_time = max(base_time, 20)  # Minimum 20 seconds for any AI processing
                
            # Large file complexity multiplier
            if char_count > 30000:  # Large files may need more complex chunking
                base_time *= 1.3
                
            # Add inter-file delay to estimates
            base_time += self.config['inter_file_delay']
                
            return base_time
            
        except Exception:
            return 60.0  # Default conservative estimate
            
    def create_job(self, file_path: Path, output_dir: Path) -> FileJob:
        """Create a processing job for a file."""
        content_type, priority = self.classifier.classify_content(file_path)
        
        # Create output path with content-based subdirectory
        output_subdir = output_dir / content_type.value
        output_subdir.mkdir(parents=True, exist_ok=True)
        output_path = output_subdir / file_path.name
        
        # Get file size
        try:
            content = file_path.read_text(encoding='utf-8', errors='ignore')
            size_chars = len(content)
        except Exception:
            size_chars = 0
            
        estimated_time = self.estimate_processing_time(file_path)
        
        return FileJob(
            file_path=file_path,
            output_path=output_path,
            content_type=content_type,
            priority=priority,
            size_chars=size_chars,
            estimated_time=estimated_time
        )
        
    def queue_jobs(self, input_dir: Path, output_dir: Path, pattern: str = "*.md"):
        """Discover files and queue processing jobs."""
        files = self.discover_files(input_dir, pattern)
        
        for file_path in files:
            job = self.create_job(file_path, output_dir)
            # Use priority value for queue ordering
            self.job_queue.put((job.priority.value, id(job), job))
            
        self.stats['total_files'] = len(files)
        
        # Calculate estimated completion time (conservative for thermal safety)
        total_time = sum(job.estimated_time for _, _, job in list(self.job_queue.queue))
        self.stats['estimated_completion'] = datetime.now() + timedelta(seconds=total_time)
        
        print(f"📊 Thermal-safe processing queue prepared:")
        print(f"   High Priority: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.HIGH)}")
        print(f"   Medium Priority: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.MEDIUM)}")
        print(f"   Low Priority: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.LOW)}")
        print(f"   Background: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.BACKGROUND)}")
        print(f"   Estimated total time: {total_time:.1f} seconds ({total_time/3600:.1f} hours)")
        print(f"🌡️ Thermal monitoring: Pause at {self.config['temp_threshold_pause']}°C, Resume at {self.config['temp_threshold_resume']}°C")
        
    def process_job(self, job: FileJob) -> bool:
        """Process a single job with thermal safety."""
        try:
            job.status = ProcessingStatus.IN_PROGRESS
            job.processing_start = datetime.now()
            
            # Check thermal status before processing
            if not self.thermal_manager.wait_for_thermal_safety():
                job.status = ProcessingStatus.THERMAL_PAUSED
                return False
            
            # Determine which tool to use based on file characteristics
            tool = self.config['processing_tools']['enhanced']  # Always use enhanced for quality
            
            cmd = [
                tool,
                '--input', str(job.file_path.parent),
                '--output', str(job.output_path.parent), 
                '--pattern', job.file_path.name,
                '--force'
            ]
            
            print(f"🔄 Processing: {job.file_path.name} ({job.content_type.value}, {job.size_chars:,} chars)")
            
            # Execute processing with generous timeout for thermal safety
            timeout_seconds = int(job.estimated_time * self.config['timeout_multiplier'])
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout_seconds
            )
            
            if result.returncode == 0:
                job.status = ProcessingStatus.COMPLETED
                job.processing_end = datetime.now()
                processing_time = (job.processing_end - job.processing_start).total_seconds()
                print(f"✅ Completed: {job.file_path.name} ({processing_time:.1f}s)")
                
                # Inter-file delay for thermal management
                print(f"❄️ Cooling delay: {self.config['inter_file_delay']}s")
                time.sleep(self.config['inter_file_delay'])
                
                return True
            else:
                job.status = ProcessingStatus.FAILED
                job.error_message = result.stderr
                print(f"❌ Failed: {job.file_path.name} - {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            job.status = ProcessingStatus.FAILED
            job.error_message = "Processing timeout"
            print(f"⏰ Timeout: {job.file_path.name}")
            return False
        except Exception as e:
            job.status = ProcessingStatus.FAILED
            job.error_message = str(e)
            print(f"💥 Error: {job.file_path.name} - {e}")
            return False
            
    def worker_thread(self):
        """Single worker thread for thermal-safe processing."""
        while True:
            try:
                priority, job_id, job = self.job_queue.get(timeout=1)
                
                success = False
                for attempt in range(self.config['retry_attempts'] + 1):
                    job.attempts = attempt + 1
                    
                    # Check thermal status before each attempt
                    thermal_state, temp = self.thermal_manager.check_thermal_status()
                    if thermal_state in [ThermalState.CRITICAL, ThermalState.COOLING]:
                        print(f"🌡️ Thermal pause: {temp:.1f}°C - Waiting for cooling")
                        self.stats['thermal_pauses'] += 1
                        if not self.thermal_manager.wait_for_thermal_safety():
                            job.status = ProcessingStatus.THERMAL_PAUSED
                            self.thermal_paused_jobs.append(job)
                            break
                    
                    success = self.process_job(job)
                    if success:
                        break
                    elif attempt < self.config['retry_attempts']:
                        print(f"🔄 Retrying {job.file_path.name} (attempt {attempt + 2})")
                        time.sleep(10)  # Brief delay between retries
                        
                if success:
                    self.completed_jobs.append(job)
                    self.stats['completed_files'] += 1
                else:
                    self.failed_jobs.append(job)
                    if job.status != ProcessingStatus.THERMAL_PAUSED:
                        self.stats['failed_files'] += 1
                        
                self.job_queue.task_done()
                
            except queue.Empty:
                continue
            except KeyboardInterrupt:
                print("\\n🛑 Worker interrupted")
                break
            except Exception as e:
                print(f"💥 Worker error: {e}")
                
    def run(self, input_dir: Path, output_dir: Path, pattern: str = "*.md"):
        """Run thermal-safe batch processing."""
        self.stats['start_time'] = datetime.now()
        
        print(f"🌡️ Starting thermal-safe batch processing")
        print(f"📁 Input: {input_dir}")
        print(f"📁 Output: {output_dir}")
        print(f"⚙️ Workers: {self.config['max_workers']} (thermal-safe mode)")
        print(f"🌡️ Temperature thresholds: {self.config['temp_threshold_pause']}°C pause / {self.config['temp_threshold_resume']}°C resume")
        
        # Initial thermal check
        thermal_state, temp = self.thermal_manager.check_thermal_status()
        if temp > 0:
            print(f"🌡️ Current temperature: {temp:.1f}°C")
        
        # Queue all jobs
        self.queue_jobs(input_dir, output_dir, pattern)
        
        if self.stats['total_files'] == 0:
            print("❌ No files found to process")
            return
            
        # Start single worker thread
        worker = threading.Thread(target=self.worker_thread, daemon=True)
        worker.start()
        
        # Progress monitoring
        try:
            while not self.job_queue.empty() or any(job.status == ProcessingStatus.IN_PROGRESS for job in self.completed_jobs + self.failed_jobs + self.thermal_paused_jobs):
                total_processed = self.stats['completed_files'] + self.stats['failed_files']
                progress_pct = (total_processed / self.stats['total_files']) * 100
                elapsed = (datetime.now() - self.stats['start_time']).total_seconds()
                
                # Thermal status
                thermal_state, temp = self.thermal_manager.check_thermal_status()
                thermal_indicator = ""
                if temp > 0:
                    if thermal_state == ThermalState.CRITICAL:
                        thermal_indicator = f" 🔥{temp:.1f}°C"
                    elif thermal_state == ThermalState.COOLING:
                        thermal_indicator = f" ❄️{temp:.1f}°C"
                    elif thermal_state == ThermalState.WARNING:
                        thermal_indicator = f" ⚠️{temp:.1f}°C"
                    else:
                        thermal_indicator = f" 🌡️{temp:.1f}°C"
                
                print(f"\\r📊 Progress: {total_processed}/{self.stats['total_files']} ({progress_pct:.1f}%) | "
                      f"✅ {self.stats['completed_files']} | ❌ {self.stats['failed_files']} | "
                      f"🌡️ {self.stats['thermal_pauses']} pauses | ⏱️ {elapsed:.0f}s{thermal_indicator}", 
                      end="", flush=True)
                
                time.sleep(5)  # Update every 5 seconds
                
        except KeyboardInterrupt:
            print("\\n🛑 Processing interrupted by user")
            
        # Final summary
        print("\\n\\n📊 Thermal-safe batch processing completed!")
        print(f"✅ Completed: {self.stats['completed_files']} files")
        print(f"❌ Failed: {self.stats['failed_files']} files")
        print(f"⏸️ Thermal pauses: {self.stats['thermal_pauses']}")
        
        total_time = (datetime.now() - self.stats['start_time']).total_seconds()
        print(f"⏱️ Total processing time: {total_time:.1f}s ({total_time/3600:.1f} hours)")
        
        if self.completed_jobs:
            avg_time = sum((job.processing_end - job.processing_start).total_seconds() 
                          for job in self.completed_jobs if job.processing_end) / len(self.completed_jobs)
            print(f"📈 Average processing time per file: {avg_time:.1f}s")

def main():
    parser = argparse.ArgumentParser(description="Thermal-Safe Transcript Batch Controller")
    parser.add_argument("input_dir", help="Input directory containing transcripts")
    parser.add_argument("--output", "-o", help="Output directory for processed transcripts", 
                       default="./thermal_safe_output")
    parser.add_argument("--pattern", "-p", default="*.md", help="File pattern to match")
    parser.add_argument("--workers", "-w", type=int, default=1, help="Number of worker threads (max 1 for thermal safety)")
    parser.add_argument("--config", "-c", help="Configuration file path")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be processed without processing")
    
    args = parser.parse_args()
    
    # Force single worker for thermal safety
    if args.workers > 1:
        print("⚠️ Multiple workers not supported in thermal-safe mode, using 1 worker")
        args.workers = 1
    
    input_dir = Path(args.input_dir)
    output_dir = Path(args.output)
    
    if not input_dir.exists():
        print(f"❌ Input directory not found: {input_dir}")
        sys.exit(1)
        
    output_dir.mkdir(parents=True, exist_ok=True)
    
    config_path = Path(args.config) if args.config else None
    controller = SafeBatchController(config_path)
    
    if args.dry_run:
        print("🔍 Dry run - analyzing files without processing...")
        files = controller.discover_files(input_dir, args.pattern)
        
        for file_path in files:
            job = controller.create_job(file_path, output_dir)
            print(f"📄 {file_path.name}")
            print(f"   Type: {job.content_type.value} | Priority: {job.priority.name}")
            print(f"   Size: {job.size_chars:,} chars | Est. time: {job.estimated_time:.1f}s")
            print(f"   Output: {job.output_path}")
            print()
            
        print(f"Total files: {len(files)}")
        return
        
    controller.run(input_dir, output_dir, args.pattern)

if __name__ == "__main__":
    main()
      '';
    };

    home.file.".local/bin/transcript-batch-controller-safe" = {
      text = ''
#!/usr/bin/env bash
set -euo pipefail
exec python3 ${scriptPath} "$@"
      '';
      executable = true;
    };
  };
}