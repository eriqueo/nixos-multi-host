{ config, lib, pkgs, ... }:

let
  cfg = config.my.ai.transcriptCheckpointManager;
  appRoot = "${config.xdg.dataHome}/transcript-checkpoint-manager";
  scriptPath = "${appRoot}/checkpoint_manager.py";
in
{
  options.my.ai.transcriptCheckpointManager = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
  };

  config = lib.mkIf cfg.enable {
    home.activation.transcriptCheckpointManagerDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${appRoot}
    '';

    home.file."${scriptPath}" = {
      text = ''
        #!/usr/bin/env python3
        """
        Transcript Checkpoint Manager - Recovery system for interrupted processing
        """
        import json, os, sys, time, argparse
        from datetime import datetime
        from pathlib import Path
        from typing import Dict, List, Optional, Any

        class TranscriptCheckpoint:
            def __init__(self, checkpoint_dir: Path):
                self.checkpoint_dir = checkpoint_dir
                self.checkpoint_dir.mkdir(parents=True, exist_ok=True)
                
            def save_checkpoint(self, file_path: str, chunks: List[str], processed_chunks: Dict[int, str], 
                              metadata: Dict[str, Any]) -> str:
                """Save processing state to checkpoint file."""
                checkpoint_id = f"{Path(file_path).stem}_{int(time.time())}"
                checkpoint_file = self.checkpoint_dir / f"{checkpoint_id}.json"
                
                checkpoint_data = {
                    "checkpoint_id": checkpoint_id,
                    "file_path": file_path,
                    "timestamp": datetime.utcnow().isoformat() + "Z",
                    "total_chunks": len(chunks),
                    "processed_chunks": len(processed_chunks),
                    "chunks": chunks,
                    "processed_results": processed_chunks,
                    "metadata": metadata,
                    "status": "in_progress"
                }
                
                checkpoint_file.write_text(json.dumps(checkpoint_data, indent=2))
                print(f"💾 Checkpoint saved: {checkpoint_id}")
                return checkpoint_id
                
            def load_checkpoint(self, checkpoint_id: str) -> Optional[Dict[str, Any]]:
                """Load checkpoint data."""
                checkpoint_file = self.checkpoint_dir / f"{checkpoint_id}.json"
                if not checkpoint_file.exists():
                    return None
                    
                try:
                    return json.loads(checkpoint_file.read_text())
                except Exception as e:
                    print(f"❌ Error loading checkpoint {checkpoint_id}: {e}")
                    return None
                    
            def list_checkpoints(self, file_path: Optional[str] = None) -> List[Dict[str, Any]]:
                """List available checkpoints, optionally filtered by file."""
                checkpoints = []
                
                for checkpoint_file in self.checkpoint_dir.glob("*.json"):
                    try:
                        data = json.loads(checkpoint_file.read_text())
                        if file_path is None or data.get("file_path") == file_path:
                            checkpoints.append(data)
                    except Exception:
                        continue
                        
                return sorted(checkpoints, key=lambda x: x.get("timestamp", ""), reverse=True)
                
            def mark_completed(self, checkpoint_id: str, output_path: str):
                """Mark checkpoint as completed."""
                checkpoint_file = self.checkpoint_dir / f"{checkpoint_id}.json"
                if checkpoint_file.exists():
                    try:
                        data = json.loads(checkpoint_file.read_text())
                        data["status"] = "completed"
                        data["output_path"] = output_path
                        data["completed_timestamp"] = datetime.utcnow().isoformat() + "Z"
                        checkpoint_file.write_text(json.dumps(data, indent=2))
                        print(f"✅ Checkpoint marked as completed: {checkpoint_id}")
                    except Exception as e:
                        print(f"❌ Error updating checkpoint: {e}")
                        
            def cleanup_old_checkpoints(self, days: int = 7):
                """Remove checkpoints older than specified days."""
                cutoff = time.time() - (days * 24 * 60 * 60)
                cleaned = 0
                
                for checkpoint_file in self.checkpoint_dir.glob("*.json"):
                    try:
                        if checkpoint_file.stat().st_mtime < cutoff:
                            data = json.loads(checkpoint_file.read_text())
                            # Only remove completed checkpoints
                            if data.get("status") == "completed":
                                checkpoint_file.unlink()
                                cleaned += 1
                    except Exception:
                        continue
                        
                if cleaned > 0:
                    print(f"🧹 Cleaned {cleaned} old checkpoints")
                    
            def resume_processing(self, checkpoint_id: str) -> Dict[str, Any]:
                """Resume processing from checkpoint."""
                checkpoint_data = self.load_checkpoint(checkpoint_id)
                if not checkpoint_data:
                    raise ValueError(f"Checkpoint {checkpoint_id} not found")
                    
                if checkpoint_data.get("status") == "completed":
                    print(f"✅ Checkpoint {checkpoint_id} already completed")
                    return checkpoint_data
                    
                print(f"🔄 Resuming from checkpoint: {checkpoint_id}")
                print(f"📄 File: {checkpoint_data['file_path']}")
                print(f"📊 Progress: {checkpoint_data['processed_chunks']}/{checkpoint_data['total_chunks']} chunks")
                
                return checkpoint_data

        def main():
            parser = argparse.ArgumentParser(description="Transcript Checkpoint Manager")
            parser.add_argument("--checkpoint-dir", 
                               default=os.path.expanduser("~/.local/share/transcripts/checkpoints"),
                               help="Directory to store checkpoints")
            
            subparsers = parser.add_subparsers(dest="command", help="Commands")
            
            # List checkpoints
            list_parser = subparsers.add_parser("list", help="List checkpoints")
            list_parser.add_argument("--file", help="Filter by file path")
            list_parser.add_argument("--status", choices=["in_progress", "completed"], 
                                   help="Filter by status")
            
            # Resume processing
            resume_parser = subparsers.add_parser("resume", help="Resume from checkpoint")
            resume_parser.add_argument("checkpoint_id", help="Checkpoint ID to resume")
            
            # Clean old checkpoints
            clean_parser = subparsers.add_parser("clean", help="Clean old checkpoints")
            clean_parser.add_argument("--days", type=int, default=7, 
                                    help="Remove completed checkpoints older than N days")
            
            # Status command
            status_parser = subparsers.add_parser("status", help="Show checkpoint status")
            status_parser.add_argument("checkpoint_id", help="Checkpoint ID")
            
            args = parser.parse_args()
            
            if not args.command:
                parser.print_help()
                return
                
            checkpoint_manager = TranscriptCheckpoint(Path(args.checkpoint_dir))
            
            if args.command == "list":
                checkpoints = checkpoint_manager.list_checkpoints(args.file)
                
                if args.status:
                    checkpoints = [cp for cp in checkpoints if cp.get("status") == args.status]
                    
                if not checkpoints:
                    print("No checkpoints found")
                    return
                    
                print(f"{'ID':<25} {'File':<30} {'Status':<12} {'Progress':<10} {'Date'}")
                print("-" * 90)
                
                for cp in checkpoints:
                    file_name = Path(cp["file_path"]).name if cp.get("file_path") else "Unknown"
                    progress = f"{cp.get('processed_chunks', 0)}/{cp.get('total_chunks', 0)}"
                    timestamp = cp.get("timestamp", "")[:16].replace("T", " ")
                    
                    print(f"{cp['checkpoint_id']:<25} {file_name:<30} {cp.get('status', 'unknown'):<12} {progress:<10} {timestamp}")
                    
            elif args.command == "resume":
                try:
                    checkpoint_data = checkpoint_manager.resume_processing(args.checkpoint_id)
                    # Here you would call your enhanced formatter with resume data
                    print("Use this data to resume processing in enhanced-transcript-formatter")
                    print(f"Remaining chunks: {len(checkpoint_data['chunks']) - len(checkpoint_data['processed_results'])}")
                except Exception as e:
                    print(f"❌ Error resuming: {e}")
                    
            elif args.command == "clean":
                checkpoint_manager.cleanup_old_checkpoints(args.days)
                
            elif args.command == "status":
                checkpoint_data = checkpoint_manager.load_checkpoint(args.checkpoint_id)
                if not checkpoint_data:
                    print(f"❌ Checkpoint {args.checkpoint_id} not found")
                    return
                    
                print(f"Checkpoint ID: {checkpoint_data['checkpoint_id']}")
                print(f"File: {checkpoint_data['file_path']}")
                print(f"Status: {checkpoint_data.get('status', 'unknown')}")
                print(f"Progress: {checkpoint_data.get('processed_chunks', 0)}/{checkpoint_data.get('total_chunks', 0)} chunks")
                print(f"Created: {checkpoint_data.get('timestamp', 'unknown')}")
                if checkpoint_data.get('completed_timestamp'):
                    print(f"Completed: {checkpoint_data['completed_timestamp']}")

        if __name__ == "__main__":
            main()
      '';
      executable = true;
    };

    home.file.".local/bin/transcript-checkpoint" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec python3 ${scriptPath} "$@"
      '';
      executable = true;
    };
  };
}