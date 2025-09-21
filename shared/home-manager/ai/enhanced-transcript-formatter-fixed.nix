{ config, lib, pkgs, ... }:

let
  cfg = config.my.ai.enhancedTranscriptFormatter;
  appRoot = "${config.xdg.dataHome}/enhanced-transcript-formatter";
  inputDirDefault = "${config.xdg.dataHome}/transcripts/input_transcripts";
  outputDirDefault = "${config.xdg.dataHome}/transcripts/enhanced_transcripts";
  scriptPath = "${appRoot}/enhanced_formatter.py";
in
{
  options.my.ai.enhancedTranscriptFormatter = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
    model = lib.mkOption { type = lib.types.str; default = "qwen2.5:7b"; };
    host = lib.mkOption { type = lib.types.str; default = "http://127.0.0.1:11434"; };
    inputDir = lib.mkOption { type = lib.types.str; default = inputDirDefault; };
    outputDir = lib.mkOption { type = lib.types.str; default = outputDirDefault; };
    interval = lib.mkOption { type = lib.types.str; default = "15m"; };
  };

  config = lib.mkIf cfg.enable {
    home.activation.enhancedTranscriptFormatterDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${appRoot} ${cfg.inputDir} ${cfg.outputDir}
    '';

    home.file."${scriptPath}" = {
      executable = true;
      text = ''
#!/usr/bin/env python3
import argparse, json, os, re, sys, time, threading, concurrent.futures
from datetime import datetime
from pathlib import Path
import requests
from typing import List, Dict, Tuple, Optional

# Enhanced patterns for better cleaning
FILLER_PAT = re.compile(r"\b(?:um+|uh+|ah+|er+|hmm+|you know|like|sort of|kind of|i mean|well,|so,|basically|literally|right\?|okay|ok|actually|obviously)\b", re.IGNORECASE)
MULTISPACE_PAT = re.compile(r"[ \t]{2,}")
TRAILING_SPACE_PAT = re.compile(r"[ \t]+$", re.MULTILINE)
FENCE_PAT = re.compile(r"(^```[\s\S]*?^```)", re.MULTILINE)
SPEAKER_PAT = re.compile(r"^([A-Z][a-z]+(?:\s+[A-Z][a-z]*)*):|\b([A-Z][a-z]+):\s", re.MULTILINE)
TOPIC_BREAK_PAT = re.compile(r"\n\s*(?:now|next|so|moving on|lets talk about|lets discuss|another|the next)", re.IGNORECASE)

# Enhanced system prompts for different content types
WEBINAR_SYSTEM_PROMPT = """You are a meticulous technical writer specializing in business and educational content. Rewrite the USER transcript into clean, professional Markdown with a clear structure:

- Add logical H1/H2/H3 headings based on topics and speaker transitions
- Use concise paragraphs and bullet/numbered lists for key points
- Bold important business terms, metrics, and key concepts the speaker actually used
- Preserve all specific numbers, percentages, dates, and technical details verbatim
- Remove conversational filler but keep the instructional essence and examples
- Maintain speaker credibility and expertise tone
- Create clear section breaks for different topics or speakers
- Keep URLs, company names, and proper nouns unchanged
- Use American English with consistent business terminology

Output valid Markdown only, no preamble or commentary. Focus on creating a professional document that preserves all factual content while dramatically improving readability."""

def chunk_content(text: str, max_tokens: int = 3000) -> List[str]:
    """Intelligently chunk content for optimal AI processing."""
    if len(text) <= max_tokens:
        return [text]
    
    chunks = []
    # Find natural breaks (speaker changes, topic transitions)
    breaks = [m.start() for m in SPEAKER_PAT.finditer(text)] + [m.start() for m in TOPIC_BREAK_PAT.finditer(text)]
    breaks = sorted(set(breaks + [0, len(text)]))
    
    current_chunk = ""
    for i in range(len(breaks) - 1):
        segment = text[breaks[i]:breaks[i+1]]
        if len(current_chunk + segment) <= max_tokens:
            current_chunk += segment
        else:
            if current_chunk:
                chunks.append(current_chunk.strip())
            current_chunk = segment
    
    if current_chunk:
        chunks.append(current_chunk.strip())
    
    return [c for c in chunks if c.strip()]

def call_ollama(text: str, model: str, host: str, temperature: float, top_p: float, timeout: int = 120) -> str:
    """Call Ollama API with timeout and error handling."""
    payload = {
        "model": model,
        "stream": False,
        "prompt": text,
        "system": WEBINAR_SYSTEM_PROMPT,
        "options": {
            "temperature": temperature,
            "top_p": top_p,
            "num_ctx": 4096
        }
    }
    
    try:
        response = requests.post(f"{host}/api/generate", json=payload, timeout=timeout)
        response.raise_for_status()
        return response.json().get("response", "").strip()
    except requests.exceptions.Timeout:
        raise Exception(f"Ollama request timed out after {timeout}s")
    except requests.exceptions.RequestException as e:
        raise Exception(f"Ollama request failed: {str(e)}")

def process_file(src: Path, dst_dir: Path, model: str, host: str, temperature: float, top_p: float, force: bool) -> Path:
    """Process transcript file with full AI enhancement and structural organization."""
    
    dst = dst_dir / src.name
    
    if dst.exists() and not force:
        print(f"⏭️ Skipping {src.name} (already processed, use --force to override)")
        return dst
        
    print(f"\n📄 Processing: {src.name}")
    
    try:
        raw = src.read_text(encoding="utf-8", errors="ignore")
        print(f"📏 Original size: {len(raw)} characters")
        
        # Clean up basic issues first
        cleaned = FILLER_PAT.sub("", raw)
        cleaned = MULTISPACE_PAT.sub(" ", cleaned)
        cleaned = TRAILING_SPACE_PAT.sub("", cleaned)
        print(f"🧹 After cleanup: {len(cleaned)} characters")
        
        # Chunk content for AI processing
        chunks = chunk_content(cleaned)
        print(f"📦 Split into {len(chunks)} chunks for AI processing")
        
        # Process chunks with AI
        processed_chunks = []
        for i, chunk in enumerate(chunks, 1):
            print(f"🤖 Processing chunk {i}/{len(chunks)}... ", end="", flush=True)
            
            # Dynamic timeout based on chunk size
            timeout = max(60, len(chunk) // 100)
            
            try:
                enhanced = call_ollama(chunk, model, host, temperature, top_p, timeout)
                processed_chunks.append(enhanced)
                print("✅")
            except Exception as e:
                print(f"❌ Error: {str(e)}")
                # Fallback to basic cleanup for failed chunks
                processed_chunks.append(f"## Transcript Section {i}\n\n{chunk}")
        
        # Combine processed chunks
        final_content = "\n\n---\n\n".join(processed_chunks)
        
        # Add metadata header
        metadata = f"""# Enhanced Transcript: {src.stem}

**Processed**: {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}  
**Model**: {model}  
**Chunks**: {len(chunks)}  

---

"""
        
        final_output = metadata + final_content
        dst.write_text(final_output, encoding="utf-8")
        
        print(f"✅ Successfully enhanced {src.name}")
        print(f"📊 Final size: {len(final_output)} characters")
        return dst
        
    except Exception as e:
        print(f"❌ Failed to process {src.name}: {str(e)}")
        raise

def main():
    parser = argparse.ArgumentParser(description="Enhanced Transcript Formatter")
    parser.add_argument("--input", "-i", default=os.environ.get("TRANSCRIPTS_INPUT", "${inputDirDefault}"))
    parser.add_argument("--output", "-o", default=os.environ.get("TRANSCRIPTS_OUTPUT", "${outputDirDefault}"))
    parser.add_argument("--pattern", "-p", default="*.md", help="File pattern to match")
    parser.add_argument("--force", "-f", action="store_true", help="Force reprocess existing files")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    
    args = parser.parse_args()
    
    in_dir = Path(args.input)
    out_dir = Path(args.output)
    out_dir.mkdir(parents=True, exist_ok=True)
    
    files = sorted(in_dir.glob(args.pattern))
    
    if not files:
        print(f"❌ No files matching {args.pattern} in {in_dir}")
        sys.exit(1)
        
    print(f"🚀 Enhanced Transcript Formatter (Test Version)")
    print(f"📁 Input: {in_dir}")
    print(f"📁 Output: {out_dir}")
    print(f"📋 Files to process: {len(files)}")
    
    for file_path in files:
        try:
            process_file(file_path, out_dir, "${cfg.model}", "${cfg.host}", 0.2, 0.9, args.force)
        except KeyboardInterrupt:
            print("\n🛑 Process interrupted by user")
            break
        except Exception as e:
            print(f"❌ Error processing {file_path.name}: {str(e)}")

if __name__ == "__main__":
    main()
      '';
    };

    home.file.".local/bin/enhanced-transcript-formatter" = {
      text = ''
#!/usr/bin/env bash
set -euo pipefail
exec python3 ${scriptPath} "$@"
      '';
      executable = true;
    };
  };
}