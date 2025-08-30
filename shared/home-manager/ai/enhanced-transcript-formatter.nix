{ config, lib, pkgs, ... }:

let
  cfg = config.my.ai.enhancedTranscriptFormatter;
  appRoot = "${config.xdg.dataHome}/enhanced-transcript-formatter";
  inputDirDefault = "${config.xdg.dataHome}/transcripts/input_transcripts";
  outputDirDefault = "${config.xdg.dataHome}/transcripts/cleaned_transcripts";
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
    # Python environment provided by shared-python.nix

    home.activation.enhancedTranscriptFormatterDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${appRoot} ${cfg.inputDir} ${cfg.outputDir}
    '';

    home.file."${scriptPath}" = {
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
        FENCE_PAT = re.compile(r"(^```[\\s\\S]*?^```)", re.MULTILINE)
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

        INTERVIEW_SYSTEM_PROMPT = """You are a professional transcript editor specializing in interview content. Transform this transcript into clean, structured Markdown:

        - Preserve speaker identification and dialogue flow
        - Create clear Q&A structure with proper headings
        - Bold important quotes and key insights
        - Remove filler while maintaining conversational authenticity
        - Organize content by topics discussed
        - Preserve all factual information, names, and specific details
        - Use bullet points for lists and key takeaways

        Output clean Markdown preserving the interview's natural flow while enhancing readability."""

        TECHNICAL_SYSTEM_PROMPT = """You are a technical writer expert in creating documentation. Clean this technical transcript:

        - Preserve ALL technical terms, commands, code snippets, and procedures exactly
        - Create step-by-step sections with proper numbering
        - Bold technical terms and important concepts
        - Use code blocks for any mentioned commands or code
        - Organize by technical topics and procedures
        - Remove filler but preserve instructional accuracy
        - Include all warnings, tips, and technical details mentioned

        Output technical Markdown documentation maintaining 100% accuracy of technical information."""

        class ProgressTracker:
            def __init__(self, total_chunks: int):
                self.total_chunks = total_chunks
                self.completed_chunks = 0
                self.current_chunk = 0
                self.start_time = time.time()
                self.lock = threading.Lock()
                
            def update(self, chunk_num: int, status: str = "processing"):
                with self.lock:
                    if status == "completed":
                        self.completed_chunks += 1
                    self.current_chunk = chunk_num
                    elapsed = time.time() - self.start_time
                    if self.completed_chunks > 0:
                        avg_time = elapsed / self.completed_chunks
                        remaining = (self.total_chunks - self.completed_chunks) * avg_time
                        eta = int(remaining)
                        eta_str = f"{eta//60}m {eta%60}s" if eta >= 60 else f"{eta}s"
                        print(f"\\r[{self.completed_chunks}/{self.total_chunks}] Processing chunk {chunk_num+1} | ETA: {eta_str}", end="", flush=True)
                    else:
                        print(f"\\r[{self.completed_chunks}/{self.total_chunks}] Processing chunk {chunk_num+1} | Starting...", end="", flush=True)
                        
            def finish(self):
                elapsed = time.time() - self.start_time
                print(f"\\n✅ Completed {self.total_chunks} chunks in {elapsed:.1f}s")

        def detect_content_type(text: str) -> str:
            """Detect the type of content to use appropriate prompts."""
            text_lower = text.lower()
            
            # Check for webinar patterns
            webinar_indicators = ['webinar', 'presentation', 'slide', 'agenda', 'housekeeping', 'q&a', 'questions']
            webinar_score = sum(1 for indicator in webinar_indicators if indicator in text_lower)
            
            # Check for interview patterns  
            interview_indicators = ['interview', 'host:', 'guest:', 'question:', 'answer:', 'thanks for joining']
            interview_score = sum(1 for indicator in interview_indicators if indicator in text_lower)
            
            # Check for technical patterns
            tech_indicators = ['command', 'script', 'function', 'variable', 'install', 'configure', 'terminal']
            tech_score = sum(1 for indicator in tech_indicators if indicator in text_lower)
            
            # Return the type with highest score
            scores = {'webinar': webinar_score, 'interview': interview_score, 'technical': tech_score}
            return max(scores.items(), key=lambda x: x[1])[0]

        def get_system_prompt(content_type: str) -> str:
            """Get appropriate system prompt based on content type."""
            prompts = {
                'webinar': WEBINAR_SYSTEM_PROMPT,
                'interview': INTERVIEW_SYSTEM_PROMPT, 
                'technical': TECHNICAL_SYSTEM_PROMPT
            }
            return prompts.get(content_type, WEBINAR_SYSTEM_PROMPT)

        def strip_filler(text: str) -> str:
            """Enhanced filler word removal with better preservation of structure."""
            # Preserve code fences
            fences = []
            def _stash(m):
                fences.append(m.group(1))
                return f"@@FENCE{len(fences)-1}@@"
            masked = FENCE_PAT.sub(_stash, text)
            
            # Remove filler words more aggressively
            masked = FILLER_PAT.sub("", masked)
            masked = MULTISPACE_PAT.sub(" ", masked)
            masked = TRAILING_SPACE_PAT.sub("", masked)
            
            lines = masked.splitlines()
            out_lines = []
            for ln in lines:
                if not ln.strip():
                    out_lines.append(ln)
                    continue
                    
                # Skip lines that are likely formatting artifacts
                if ln.lstrip().startswith(("-", "*", ">", "```", "    ", "\\t")):
                    out_lines.append(ln)
                    continue
                    
                stripped = ln.strip()
                if stripped:
                    # Capitalize first letter if it looks like a sentence start
                    if re.match(r"[a-z]", stripped[0]):
                        stripped = stripped[0].upper() + stripped[1:]
                    # Add period if it looks like end of sentence
                    if re.search(r"[A-Za-z0-9)]$", stripped) and not stripped.endswith(('.', '!', '?', ':')):
                        stripped += "."
                    leading = len(ln) - len(ln.lstrip(" "))
                    out_lines.append(" " * leading + stripped)
                else:
                    out_lines.append(ln)
                    
            masked = "\\n".join(out_lines)
            
            # Restore code fences
            def _unstash(m):
                idx = int(m.group(0)[8:-2])
                return fences[idx] if idx < len(fences) else m.group(0)
            return re.sub(r"@@FENCE(\\d+)@@", _unstash, masked).strip()

        def smart_split_content(text: str, target_chars: int = 8000, max_chars: int = 12000) -> List[str]:
            """Intelligent content-aware chunking that respects topic boundaries."""
            
            # First try to split on major topic breaks
            topic_splits = TOPIC_BREAK_PAT.split(text)
            if len(topic_splits) > 1:
                chunks = []
                current_chunk = ""
                
                for i, segment in enumerate(topic_splits):
                    # Re-add the split pattern to maintain context
                    if i > 0 and i < len(topic_splits):
                        segment = topic_splits[i-1][-50:] + segment  # Add some overlap
                        
                    test_chunk = current_chunk + ("\\n\\n" if current_chunk else "") + segment
                    
                    if len(test_chunk) <= target_chars:
                        current_chunk = test_chunk
                    else:
                        if current_chunk:
                            chunks.append(current_chunk.strip())
                        current_chunk = segment
                        
                        # If even a single segment is too long, split by paragraphs
                        if len(current_chunk) > max_chars:
                            para_chunks = split_on_paragraphs(current_chunk, target_chars, max_chars)
                            chunks.extend(para_chunks[:-1])
                            current_chunk = para_chunks[-1] if para_chunks else ""
                
                if current_chunk:
                    chunks.append(current_chunk.strip())
                    
                return [c for c in chunks if c.strip()]
            
            # Fallback to paragraph-based splitting
            return split_on_paragraphs(text, target_chars, max_chars)

        def split_on_paragraphs(text: str, target_chars: int = 8000, hard_cap: int = 12000) -> List[str]:
            """Enhanced paragraph splitting with better boundary detection."""
            parts, buf, paras = [], [], text.split("\\n\\n")
            total = 0
            
            for para in paras:
                chunk_candidate = ("\\n\\n".join(buf + [para])).strip()
                if len(chunk_candidate) <= target_chars:
                    buf.append(para)
                    total = len(chunk_candidate)
                else:
                    if buf:
                        parts.append("\\n\\n".join(buf).strip())
                        buf = [para]
                        total = len(para)
                    else:
                        # Single paragraph too long, split by sentences
                        sentences = re.split(r'(?<=[.!?])\\s+', para)
                        current = ""
                        for sentence in sentences:
                            if len(current + " " + sentence) <= hard_cap:
                                current += (" " if current else "") + sentence
                            else:
                                if current:
                                    parts.append(current.strip())
                                current = sentence
                        if current:
                            buf = [current]
                            total = len(current)
            
            if buf:
                parts.append("\\n\\n".join(buf).strip())
                
            return parts if parts else [text]

        def ollama_chat(model: str, system: str, user: str, host: str, temperature: float, top_p: float, 
                       retries: int = 3, base_timeout: float = 120.0, complexity_multiplier: float = 1.0) -> str:
            """Enhanced Ollama chat with dynamic timeout and better error handling."""
            
            url = host.rstrip("/") + "/api/chat"
            timeout = base_timeout * complexity_multiplier
            
            payload = {
                "model": model, 
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": user}
                ], 
                "options": {"temperature": temperature, "top_p": top_p}, 
                "stream": False
            }
            
            backoff = 2.0
            last_error = None
            
            for attempt in range(retries):
                try:
                    response = requests.post(url, json=payload, timeout=timeout)
                    response.raise_for_status()
                    data = response.json()
                    content = data.get("message", {}).get("content", "")
                    if content.strip():
                        return content
                    else:
                        raise ValueError("Empty response from model")
                        
                except requests.exceptions.Timeout:
                    last_error = f"Request timed out after {timeout}s (attempt {attempt + 1}/{retries})"
                    print(f"\\n⚠️ {last_error}")
                    timeout *= 1.5  # Increase timeout for retry
                    
                except requests.exceptions.RequestException as e:
                    last_error = f"Request failed: {str(e)}"
                    print(f"\\n⚠️ {last_error}")
                    
                except Exception as e:
                    last_error = f"Unexpected error: {str(e)}"
                    print(f"\\n⚠️ {last_error}")
                
                if attempt < retries - 1:
                    print(f"🔄 Retrying in {backoff}s...")
                    time.sleep(backoff)
                    backoff = min(backoff * 1.5, 10.0)
            
            raise RuntimeError(f"Ollama chat failed after {retries} attempts. Last error: {last_error}")

        def calculate_complexity(text: str) -> float:
            """Calculate content complexity to adjust processing parameters."""
            # Factors that increase complexity
            word_count = len(text.split())
            avg_sentence_length = word_count / max(len(re.split(r'[.!?]+', text)), 1)
            technical_terms = len(re.findall(r'\\b(?:system|process|function|method|algorithm|database|API|framework)\\b', text, re.IGNORECASE))
            
            # Base complexity
            complexity = 1.0
            
            # Adjust based on length
            if word_count > 2000:
                complexity += 0.5
            if word_count > 4000:
                complexity += 0.5
                
            # Adjust based on sentence complexity
            if avg_sentence_length > 25:
                complexity += 0.3
                
            # Adjust based on technical content
            if technical_terms > 10:
                complexity += 0.4
                
            return min(complexity, 3.0)  # Cap at 3x

        def process_chunk(chunk_data: Tuple[int, str], model: str, system_prompt: str, host: str, 
                         temperature: float, top_p: float, tracker: ProgressTracker) -> Tuple[int, str]:
            """Process a single chunk with progress tracking."""
            chunk_idx, chunk = chunk_data
            tracker.update(chunk_idx, "processing")
            
            try:
                complexity = calculate_complexity(chunk)
                user_msg = f"Restructure this transcript chunk. Keep ALL real technical content and preserve factual accuracy:\\n\\n{chunk}"
                
                result = ollama_chat(
                    model=model, 
                    system=system_prompt, 
                    user=user_msg, 
                    host=host,
                    temperature=temperature, 
                    top_p=top_p,
                    complexity_multiplier=complexity
                )
                
                tracker.update(chunk_idx, "completed")
                return chunk_idx, result.strip()
                
            except Exception as e:
                print(f"\\n❌ Error processing chunk {chunk_idx + 1}: {str(e)}")
                tracker.update(chunk_idx, "failed")
                # Return original chunk as fallback
                return chunk_idx, f"## Chunk {chunk_idx + 1} (Processing Failed)\\n\\n{chunk}"

        def process_file(src: Path, dst_dir: Path, model: str, host: str, temperature: float, top_p: float, force: bool) -> Path:
            """Enhanced file processing with intelligent chunking and progress tracking."""
            
            dst = dst_dir / src.name
            meta = dst.with_suffix(".json")
            
            if dst.exists() and not force:
                print(f"⏭️ Skipping {src.name} (already processed, use --force to override)")
                return dst
                
            print(f"\\n📄 Processing: {src.name}")
            
            try:
                raw = src.read_text(encoding="utf-8", errors="ignore")
                print(f"📏 Original size: {len(raw)} characters")
                
                # Clean up filler words
                cleaned = strip_filler(raw)
                print(f"🧹 After cleanup: {len(cleaned)} characters")
                
                # Detect content type and get appropriate prompt
                content_type = detect_content_type(cleaned)
                system_prompt = get_system_prompt(content_type)
                print(f"🏷️ Detected content type: {content_type}")
                
                # Smart chunking
                chunks = smart_split_content(cleaned)
                print(f"📝 Split into {len(chunks)} chunks")
                
                if not chunks:
                    raise ValueError("No content to process after cleaning")
                
                # Process chunks with progress tracking
                tracker = ProgressTracker(len(chunks))
                structured_chunks = []
                
                # Use ThreadPoolExecutor for parallel processing of independent chunks
                max_workers = min(3, len(chunks))  # Don't overwhelm the system
                chunk_data = list(enumerate(chunks))
                
                with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
                    futures = [
                        executor.submit(process_chunk, data, model, system_prompt, host, temperature, top_p, tracker)
                        for data in chunk_data
                    ]
                    
                    # Collect results in order
                    results = {}
                    for future in concurrent.futures.as_completed(futures):
                        try:
                            chunk_idx, result = future.result()
                            results[chunk_idx] = result
                        except Exception as e:
                            print(f"\\n❌ Chunk processing failed: {str(e)}")
                
                tracker.finish()
                
                # Reassemble chunks in correct order
                structured_chunks = [results[i] for i in range(len(chunks)) if i in results]
                
                if not structured_chunks:
                    raise ValueError("All chunks failed to process")
                
                # Merge results intelligently
                if len(structured_chunks) == 1:
                    final_md = structured_chunks[0]
                else:
                    print("🔀 Merging chunks...")
                    merge_prompt = f"""Merge these {len(structured_chunks)} processed transcript chunks into a single cohesive document:

- Maintain existing headings and structure
- Remove any duplicate content or repetitive introductions
- Ensure logical flow between sections
- Preserve all factual content and technical details
- Output final Markdown only

Chunks to merge:
"""
                    merged_input = "\\n\\n---\\n\\n".join(structured_chunks)
                    
                    try:
                        final_md = ollama_chat(
                            model=model, 
                            system=system_prompt, 
                            user=merge_prompt + merged_input, 
                            host=host,
                            temperature=0.1,  # Lower temperature for merge consistency
                            top_p=0.9,
                            complexity_multiplier=1.5  # Merging is complex
                        )
                    except Exception as e:
                        print(f"⚠️ Merge failed, using concatenated chunks: {str(e)}")
                        final_md = "\\n\\n".join(structured_chunks)
                
                # Write output
                dst.write_text(final_md.strip() + "\\n", encoding="utf-8")
                
                # Save metadata
                metadata = {
                    "source": str(src),
                    "output": str(dst),
                    "model": model,
                    "host": host,
                    "temperature": temperature,
                    "top_p": top_p,
                    "content_type": content_type,
                    "chunks": len(chunks),
                    "original_chars": len(raw),
                    "cleaned_chars": len(cleaned),
                    "timestamp": datetime.utcnow().isoformat() + "Z"
                }
                meta.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
                
                print(f"✅ Successfully processed {src.name}")
                print(f"📊 Stats: {len(chunks)} chunks, {content_type} content")
                
                return dst
                
            except Exception as e:
                print(f"❌ Failed to process {src.name}: {str(e)}")
                raise

        def main():
            parser = argparse.ArgumentParser(description="Enhanced Transcript Formatter with intelligent chunking")
            parser.add_argument("--input", "-i", default=os.environ.get("TRANSCRIPTS_INPUT", "${inputDirDefault}"))
            parser.add_argument("--output", "-o", default=os.environ.get("TRANSCRIPTS_OUTPUT", "${outputDirDefault}"))
            parser.add_argument("--pattern", "-p", default="*.md", help="File pattern to match")
            parser.add_argument("--model", "-m", default=os.environ.get("OLLAMA_MODEL", "${cfg.model}"))
            parser.add_argument("--host", default=os.environ.get("OLLAMA_HOST", "${cfg.host}"))
            parser.add_argument("--force", "-f", action="store_true", help="Force reprocess existing files")
            parser.add_argument("--temperature", type=float, default=float(os.environ.get("OLLAMA_TEMPERATURE", "0.2")))
            parser.add_argument("--top_p", type=float, default=float(os.environ.get("OLLAMA_TOP_P", "0.9")))
            parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
            
            args = parser.parse_args()
            
            in_dir = Path(args.input)
            out_dir = Path(args.output)
            out_dir.mkdir(parents=True, exist_ok=True)
            
            files = sorted(in_dir.glob(args.pattern))
            
            if not files:
                print(f"❌ No files matching {args.pattern} in {in_dir}")
                sys.exit(1)
                
            print(f"🚀 Enhanced Transcript Formatter")
            print(f"📁 Input: {in_dir}")
            print(f"📁 Output: {out_dir}")
            print(f"🤖 Model: {args.model}")
            print(f"📋 Files to process: {len(files)}")
            
            errors = 0
            for file_path in files:
                try:
                    process_file(file_path, out_dir, args.model, args.host, args.temperature, args.top_p, args.force)
                except KeyboardInterrupt:
                    print("\\n🛑 Process interrupted by user")
                    break
                except Exception as e:
                    errors += 1
                    print(f"❌ Error processing {file_path.name}: {str(e)}")
                    if args.verbose:
                        import traceback
                        traceback.print_exc()
            
            if errors > 0:
                print(f"\\n⚠️ Completed with {errors} errors")
                sys.exit(1)
            else:
                print(f"\\n🎉 All files processed successfully!")

        if __name__ == "__main__":
            main()
      '';
      executable = true;
    };

    home.file.".local/bin/enhanced-transcript-formatter" = {
      text = ''
        #!/usr/bin/env bash
        set -euo pipefail
        exec python3 ${scriptPath} "$@"
      '';
      executable = true;
    };

    systemd.user.services.enhanced-transcript-formatter = {
      Unit.Description = "Enhanced transcript formatter with intelligent chunking";
      Service = {
        Type = "simple";
        Environment = [
          "TRANSCRIPTS_INPUT=${cfg.inputDir}"
          "TRANSCRIPTS_OUTPUT=${cfg.outputDir}"
          "OLLAMA_HOST=${cfg.host}"
          "OLLAMA_MODEL=${cfg.model}"
          "OLLAMA_TEMPERATURE=0.2"
          "OLLAMA_TOP_P=0.9"
          "PATH=${config.home.profileDirectory}/bin"
        ];
        ExecStart = "%h/.local/bin/enhanced-transcript-formatter";
        WorkingDirectory = "%h";
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.timers.enhanced-transcript-formatter = {
      Unit.Description = "Run enhanced transcript formatter periodically";
      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}