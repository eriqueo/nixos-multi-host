{ config, lib, pkgs, ... }:

let
  cfg = config.my.ai.transcriptBatchController;
  appRoot = "${config.xdg.dataHome}/transcript-batch-controller";
  scriptPath = "${appRoot}/batch_controller.py";
in
{
  options.my.ai.transcriptBatchController = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
  };

  config = lib.mkIf cfg.enable {
    home.activation.transcriptBatchControllerDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${appRoot}
    '';

    home.file."${scriptPath}" = {
      executable = true;
      text = ''
#!/usr/bin/env python3
"""
Transcript Batch Controller - Intelligent batch processing system for transcript collections
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

class BatchController:
    """Main batch processing controller."""
    
    def __init__(self, config_path: Optional[Path] = None):
        self.config_path = config_path or Path.home() / '.config' / 'transcript-batch-controller.json'
        self.classifier = ContentClassifier()
        self.job_queue = queue.PriorityQueue()
        self.active_jobs = {}
        self.completed_jobs = []
        self.failed_jobs = []
        self.stats = {
            'total_files': 0,
            'processed': 0,
            'failed': 0,
            'skipped': 0,
            'start_time': None,
            'estimated_completion': None
        }
        self.config = self.load_config()
        
    def load_config(self) -> Dict[str, Any]:
        """Load batch controller configuration."""
        default_config = {
            'max_workers': 3,
            'retry_attempts': 2,
            'timeout_multiplier': 2.0,
            'processing_tools': {
                'enhanced': 'enhanced-transcript-formatter',
                'basic': 'transcript-formatter'
            },
            'output_structure': {
                'business': 'business',
                'technical': 'technical', 
                'educational': 'educational',
                'archive': 'archives',
                'unknown': 'misc'
            },
            'quality_checks': True,
            'checkpoint_frequency': 5
        }
        
        if self.config_path.exists():
            try:
                with open(self.config_path, 'r') as f:
                    user_config = json.load(f)
                default_config.update(user_config)
            except Exception as e:
                print(f"⚠️ Config load failed, using defaults: {e}")
                
        return default_config
        
    def save_config(self):
        """Save current configuration."""
        try:
            self.config_path.parent.mkdir(parents=True, exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"⚠️ Config save failed: {e}")
            
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
            
            # AI processing time: ~15-20 seconds per 3000-character chunk
            chunk_size = 3000
            num_chunks = max(1, (char_count + chunk_size - 1) // chunk_size)
            
            # Base processing time per chunk (conservative estimate)
            seconds_per_chunk = 20  # Allows for model loading, inference, and context switching
            base_time = num_chunks * seconds_per_chunk
            
            # Small file minimum (model loading overhead)
            if char_count < 5000:
                base_time = max(base_time, 15)  # Minimum 15 seconds for any AI processing
                
            # Large file complexity multiplier
            if char_count > 30000:  # Large files may need more complex chunking
                base_time *= 1.2
                
            return base_time
            
        except Exception:
            return 5.0  # Default estimate
            
    def create_job(self, file_path: Path, output_base: Path) -> FileJob:
        """Create a processing job for a file."""
        content_type, priority = self.classifier.classify_content(file_path)
        
        # Determine output path based on content type
        type_dir = self.config['output_structure'].get(content_type.value, 'misc')
        output_dir = output_base / type_dir
        output_dir.mkdir(parents=True, exist_ok=True)
        output_path = output_dir / file_path.name
        
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
        
        print(f"🔍 Discovered {len(files)} transcript files")
        
        for file_path in files:
            job = self.create_job(file_path, output_dir)
            # Use priority value for queue ordering (lower = higher priority)
            self.job_queue.put((job.priority.value, id(job), job))
            
        self.stats['total_files'] = len(files)
        
        # Calculate estimated completion time
        total_time = sum(job.estimated_time for _, _, job in list(self.job_queue.queue))
        self.stats['estimated_completion'] = datetime.now() + timedelta(seconds=total_time)
        
        print(f"📊 Processing queue prepared:")
        print(f"   High Priority: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.HIGH)}")
        print(f"   Medium Priority: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.MEDIUM)}")
        print(f"   Low Priority: {sum(1 for _, _, job in list(self.job_queue.queue) if job.priority == Priority.LOW)}")
        print(f"   Estimated total time: {total_time:.1f} seconds")
        
    def select_processing_tool(self, job: FileJob) -> str:
        """Select appropriate processing tool based on job characteristics."""
        # Use enhanced formatter for high-value content
        if job.priority in [Priority.HIGH, Priority.MEDIUM]:
            return self.config['processing_tools']['enhanced']
        elif job.size_chars > 20000:  # Large files benefit from enhanced processing
            return self.config['processing_tools']['enhanced']
        else:
            return self.config['processing_tools']['basic']
            
    def process_job(self, job: FileJob) -> bool:
        """Process a single job."""
        job.processing_start = datetime.now()
        job.status = ProcessingStatus.IN_PROGRESS
        
        print(f"🔄 Processing: {job.file_path.name} ({job.content_type.value}, {job.size_chars:,} chars)")
        
        try:
            tool = self.select_processing_tool(job)
            
            # Build command
            cmd = [
                tool,
                '--input', str(job.file_path.parent),
                '--output', str(job.output_path.parent),
                '--pattern', job.file_path.name,
                '--force'
            ]
            
            # Execute processing
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=job.estimated_time * self.config['timeout_multiplier']
            )
            
            if result.returncode == 0:
                job.status = ProcessingStatus.COMPLETED
                job.processing_end = datetime.now()
                processing_time = (job.processing_end - job.processing_start).total_seconds()
                print(f"✅ Completed: {job.file_path.name} ({processing_time:.1f}s)")
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
        """Worker thread for processing jobs."""
        while True:
            try:
                priority, job_id, job = self.job_queue.get(timeout=1)
                
                success = False
                for attempt in range(self.config['retry_attempts'] + 1):
                    job.attempts = attempt + 1
                    success = self.process_job(job)
                    if success:
                        break
                    elif attempt < self.config['retry_attempts']:
                        print(f"🔄 Retrying {job.file_path.name} (attempt {attempt + 2})")
                        time.sleep(2)  # Brief delay between retries
                        
                if success:
                    self.completed_jobs.append(job)
                    self.stats['processed'] += 1
                else:
                    self.failed_jobs.append(job)
                    self.stats['failed'] += 1
                    
                self.job_queue.task_done()
                
            except queue.Empty:
                break
            except Exception as e:
                print(f"💥 Worker error: {e}")
                break
                
    def print_progress(self):
        """Print processing progress."""
        total = self.stats['total_files']
        completed = self.stats['processed'] + self.stats['failed']
        
        if total == 0:
            return
            
        progress = (completed / total) * 100
        elapsed = (datetime.now() - self.stats['start_time']).total_seconds()
        
        print(f"\\r📊 Progress: {completed}/{total} ({progress:.1f}%) | "
              f"✅ {self.stats['processed']} | ❌ {self.stats['failed']} | "
              f"⏱️ {elapsed:.0f}s", end="", flush=True)
              
    def generate_report(self) -> Dict[str, Any]:
        """Generate processing report."""
        end_time = datetime.now()
        total_time = (end_time - self.stats['start_time']).total_seconds()
        
        report = {
            'summary': {
                'total_files': self.stats['total_files'],
                'successful': len(self.completed_jobs),
                'failed': len(self.failed_jobs),
                'success_rate': (len(self.completed_jobs) / self.stats['total_files'] * 100) if self.stats['total_files'] > 0 else 0,
                'total_processing_time': total_time,
                'average_time_per_file': total_time / max(len(self.completed_jobs), 1)
            },
            'by_content_type': {},
            'by_priority': {},
            'failed_jobs': [],
            'performance_metrics': {
                'files_per_minute': (len(self.completed_jobs) / total_time * 60) if total_time > 0 else 0,
                'total_characters_processed': sum(job.size_chars for job in self.completed_jobs),
                'average_file_size': sum(job.size_chars for job in self.completed_jobs) / max(len(self.completed_jobs), 1)
            }
        }
        
        # Group by content type
        for job in self.completed_jobs + self.failed_jobs:
            ct = job.content_type.value
            if ct not in report['by_content_type']:
                report['by_content_type'][ct] = {'successful': 0, 'failed': 0, 'total': 0}
            
            report['by_content_type'][ct]['total'] += 1
            if job.status == ProcessingStatus.COMPLETED:
                report['by_content_type'][ct]['successful'] += 1
            else:
                report['by_content_type'][ct]['failed'] += 1
                
        # Group by priority
        for job in self.completed_jobs + self.failed_jobs:
            pr = job.priority.value
            if pr not in report['by_priority']:
                report['by_priority'][pr] = {'successful': 0, 'failed': 0, 'total': 0}
                
            report['by_priority'][pr]['total'] += 1
            if job.status == ProcessingStatus.COMPLETED:
                report['by_priority'][pr]['successful'] += 1
            else:
                report['by_priority'][pr]['failed'] += 1
                
        # Failed jobs details
        for job in self.failed_jobs:
            report['failed_jobs'].append({
                'file': str(job.file_path),
                'content_type': job.content_type.value,
                'priority': job.priority.value,
                'attempts': job.attempts,
                'error': job.error_message
            })
            
        return report
        
    def run_batch(self, input_dir: Path, output_dir: Path, pattern: str = "*.md"):
        """Run complete batch processing."""
        print(f"🚀 Starting batch processing")
        print(f"📁 Input: {input_dir}")
        print(f"📁 Output: {output_dir}")
        
        self.stats['start_time'] = datetime.now()
        
        # Queue all jobs
        self.queue_jobs(input_dir, output_dir, pattern)
        
        if self.stats['total_files'] == 0:
            print("❌ No files found to process")
            return
            
        # Start worker threads
        max_workers = min(self.config['max_workers'], self.stats['total_files'])
        print(f"👥 Starting {max_workers} worker threads")
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(self.worker_thread) for _ in range(max_workers)]
            
            # Progress monitoring
            while any(not f.done() for f in futures):
                self.print_progress()
                time.sleep(2)
                
            # Wait for completion
            concurrent.futures.wait(futures)
            
        print("\\n")  # New line after progress
        
        # Generate and display report
        report = self.generate_report()
        
        print(f"\\n🎉 Batch processing completed!")
        print(f"📊 Summary:")
        print(f"   ✅ Successful: {report['summary']['successful']}")
        print(f"   ❌ Failed: {report['summary']['failed']}")
        print(f"   📈 Success rate: {report['summary']['success_rate']:.1f}%")
        print(f"   ⏱️ Total time: {report['summary']['total_processing_time']:.1f}s")
        print(f"   🚀 Average per file: {report['summary']['average_time_per_file']:.1f}s")
        
        # Save detailed report
        report_path = output_dir / 'reports' / f"batch_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        report_path.parent.mkdir(parents=True, exist_ok=True)
        
        with open(report_path, 'w') as f:
            json.dump(report, f, indent=2, default=str)
            
        print(f"📋 Detailed report saved: {report_path}")
        
        return report

def main():
    parser = argparse.ArgumentParser(description="Transcript Batch Controller")
    parser.add_argument("input_dir", type=Path, help="Input directory containing transcripts")
    parser.add_argument("--output", "-o", type=Path, 
                       default=Path.home() / '.local' / 'share' / 'transcripts' / 'batch_output',
                       help="Output directory for processed transcripts")
    parser.add_argument("--pattern", "-p", default="*.md", help="File pattern to match")
    parser.add_argument("--workers", "-w", type=int, default=3, help="Number of worker threads")
    parser.add_argument("--config", "-c", type=Path, help="Configuration file path")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be processed without processing")
    
    args = parser.parse_args()
    
    if not args.input_dir.exists():
        print(f"❌ Input directory does not exist: {args.input_dir}")
        sys.exit(1)
        
    controller = BatchController(args.config)
    controller.config['max_workers'] = args.workers
    
    if args.dry_run:
        print("🔍 Dry run - discovering files and showing processing plan:")
        files = controller.discover_files(args.input_dir, args.pattern)
        
        for file_path in files:
            job = controller.create_job(file_path, args.output)
            print(f"📄 {file_path.name}")
            print(f"   Type: {job.content_type.value} | Priority: {job.priority.name}")
            print(f"   Size: {job.size_chars:,} chars | Est. time: {job.estimated_time:.1f}s")
            print(f"   Output: {job.output_path}")
            print()
            
        print(f"Total files: {len(files)}")
        return
        
    # Run batch processing
    controller.run_batch(args.input_dir, args.output, args.pattern)

if __name__ == "__main__":
    main()
      '';
    };

    home.file.".local/bin/transcript-batch-controller" = {
      text = ''
#!/usr/bin/env bash
set -euo pipefail
exec python3 ${scriptPath} "$@"
      '';
      executable = true;
    };
  };
}