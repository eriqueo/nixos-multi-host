{ config, lib, pkgs, ... }:

let
  cfg = config.my.ai.transcriptFormatter;
  appRoot = "${config.xdg.dataHome}/transcript-formatter";
  inputDirDefault = "${config.xdg.dataHome}/transcripts/input_transcripts";
  outputDirDefault = "${config.xdg.dataHome}/transcripts/cleaned_transcripts";
  scriptPath = "${appRoot}/formatter.py";
in
{
  options.my.ai.transcriptFormatter = {
    enable = lib.mkOption { type = lib.types.bool; default = false; };
    model = lib.mkOption { type = lib.types.str; default = "llama3"; };
    host = lib.mkOption { type = lib.types.str; default = "http://127.0.0.1:11434"; };
    inputDir = lib.mkOption { type = lib.types.str; default = inputDirDefault; };
    outputDir = lib.mkOption { type = lib.types.str; default = outputDirDefault; };
    interval = lib.mkOption { type = lib.types.str; default = "15m"; };
    mode = lib.mkOption { type = lib.types.enum [ "cleanup-only" "preserve-education" "summary-mode" ]; default = "preserve-education"; };
    minRetainRatio = lib.mkOption { type = lib.types.float; default = 0.70; };
    appendFull = lib.mkOption { type = lib.types.bool; default = true; };
  };

  config = lib.mkIf cfg.enable {
    # Python environment provided by shared-python.nix

    home.activation.transcriptFormatterDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      mkdir -p ${appRoot} ${cfg.inputDir} ${cfg.outputDir}
    '';

    home.file."${scriptPath}" = {
      text = ''
        #!/usr/bin/env python3
        import argparse, json, os, re, sys, time, csv
        from datetime import datetime, timezone
        from pathlib import Path
        import requests
        from typing import Dict, List, Any
        
        # Try importing yaml, fallback if not available
        try:
            import yaml
            HAS_YAML = True
        except ImportError:
            print("Warning: PyYAML not available, using JSON fallback for metadata", file=sys.stderr)
            HAS_YAML = False

        FILLER_PAT = re.compile(r"\b(?:um+|uh+|ah+|er+|hmm+|you know|like|sort of|kind of|i mean|well,|so,|basically|literally|right\?|okay|ok)\b", re.IGNORECASE)
        MULTISPACE_PAT = re.compile(r"[ \t]{2,}")
        TRAILING_SPACE_PAT = re.compile(r"[ \t]+$", re.MULTILINE)
        FENCE_PAT = re.compile(r"(^```[\\s\\S]*?^```)", re.MULTILINE)

        QA_PAT = re.compile(r"^(?:Q[:\\-]\\s|A[:\\-]\\s|Question[:\\-]\\s|Answer[:\\-]\\s)", re.IGNORECASE|re.MULTILINE)
        NUM_PAT = re.compile(r"(?<!`)(?:\\b\\d[\\d,]*(?:\\.\\d+)?\\s?(?:%|k|m|b|years?|yr|mo|weeks?|days?|hrs?|hours?|fps|gb|tb|\\$)\\b|\\$\\s?\\d[\\d,]*)(?!`)", re.IGNORECASE)
        FRAME_PAT = re.compile(r"^(?:\\d+\\.\\s+|\\-\\s+|\\*\\s+)", re.MULTILINE)
        NAME_FRAME_PAT = re.compile(r"\\b([A-Z][a-z]+(?:\\s[A-Z][a-z]+){0,2})\\b(?:\\s+(?:method|system|framework|playbook|model))", re.IGNORECASE)

        # Content-type detection patterns  
        EDUCATION_PATTERNS = [r"(?i)\b(?:webinar|seminar|training|course|lesson|tutorial|framework|system|method|strategy|case study|transformation|story|business|entrepreneur|scale|growth|revenue|profit)\b", r"(?i)\b(?:dave|randy|eric|coach|mentor|speaker|founder|ceo)\b", r"(?i)\bQ[:\-]\s|A[:\-]\s|Question[:\-]\s|Answer[:\-]\s"]
        MEETING_PATTERNS = [r"(?i)\b(?:meeting|standup|sync|action items|decisions|next steps|agenda)\b", r"(?i)\b(?:assigned|deadline|follow.?up|deliverable)\b"]
        PODCAST_PATTERNS = [r"(?i)\b(?:podcast|episode|interview|chat|conversation)\b", r"(?i)\b(?:host|guest|listener)\b"]

        # Mode-specific prompts
        PROMPTS = {
            "education": {
                "cleanup": "You are a careful editor for educational content. Remove only filler words (um, uh, you know, like) and fix basic grammar/punctuation. DO NOT summarize, compress, or remove any educational content. Preserve all stories, examples, frameworks, numbers, case studies, and Q&A sections completely intact.",
                "navigation": "Generate a table of contents and 1-3 sentence section capsules for this educational content. DO NOT rewrite the content - only create navigation aids. Identify major sections and provide brief capsules summarizing what each section covers.",
                "toc": "Create a markdown table of contents with clear H1/H2/H3 structure for this educational content. Identify natural section breaks based on topic changes, speaker changes, or Q&A transitions.",
                "extract_qa": "Extract all question-answer exchanges from this educational content. Format as JSON with speaker, question, and answer fields. Preserve the exact wording of questions and answers.",
                "extract_numbers": "Extract all numbers, metrics, financial figures, timeframes, and percentages from this content. Include context for each number (what it refers to).",
                "extract_frameworks": "Extract all named methodologies, systems, frameworks, processes, and structured approaches mentioned in this content. Include brief descriptions of each."
            },
            "meeting": {
                "cleanup": "Clean up this meeting transcript by removing filler words and fixing grammar.",
                "structure": "Summarize this meeting into key decisions, action items, and outcomes. Use bullet points and clear headings.",
                "merge": "Combine these meeting chunks into a structured summary with decisions, action items, and next steps."
            },
            "podcast": {
                "cleanup": "Remove filler words and conversational redundancy while preserving interesting anecdotes and key insights.",
                "structure": "Structure this podcast content with clear topics and key insights. Preserve interesting stories but reduce conversational redundancy.",
                "merge": "Combine these podcast chunks maintaining the conversational flow and key insights."
            },
            "default": {
                "cleanup": "Remove filler words and fix basic grammar without removing content.",
                "structure": "Add structure with headings and formatting. Preserve all important information.",
                "merge": "Merge chunks into a cohesive document with clear structure."
            }
        }

        def strip_filler(text: str) -> str:
            fences = []
            def _stash(m):
                fences.append(m.group(1))
                return f"@@FENCE{len(fences)-1}@@"
            masked = FENCE_PAT.sub(_stash, text)
            masked = FILLER_PAT.sub("", masked)
            masked = MULTISPACE_PAT.sub(" ", masked)
            masked = TRAILING_SPACE_PAT.sub("", masked)
            lines = masked.splitlines()
            out_lines = []
            for ln in lines:
                if not ln.strip():
                    out_lines.append(ln); continue
                if ln.lstrip().startswith(("-", "*", ">", "```", "    ", "\\t")):
                    out_lines.append(ln); continue
                stripped = ln.strip()
                if stripped and re.match(r"[a-z]", stripped[0]):
                    stripped = stripped[0].upper() + stripped[1:]
                if re.search(r"[A-Za-z0-9)]$", stripped):
                    stripped += "."
                leading = len(ln) - len(ln.lstrip(" "))
                out_lines.append(" " * leading + stripped)
            masked = "\\n".join(out_lines)
            def _unstash(m):
                idx = int(m.group(0)[8:-2])
                return fences[idx]
            return re.sub(r"@@FENCE(\\d+)@@", _unstash, masked).strip()

        def find_natural_breaks(text: str) -> list:
            # Natural break patterns for business/webinar content
            patterns = [
                r"(?i)(?:Now,?\\s+let[''']s|So,?\\s+(?:here[''']s|let[''']s)|Alright,?\\s+(?:so|let[''']s))",
                r"(?i)(?:Randy|Eric|Dave)\\s+(?:said|mentioned|talked about|shared)",
                r"(?i)(?:The\\s+(?:next|first|second|third|fourth|fifth)\\s+(?:thing|point|lever|step))",
                r"(?i)(?:(?:Six|6)\\s+months|(?:Two|2)\\s+years|In\\s+\\d{4}|(?:Now|So),?\\s+(?:here[''']s|this is))",
                r"(?i)(?:Let me\\s+(?:share|tell you)|I[''']m going to|We[''']re going to)",
                r"(?i)(?:Question|Answer)\\s*[:.]\\s*",
                r"(?i)(?:So\\s+guys|Alright\\s+everyone|Thanks\\s+(?:guys|everyone))"
            ]
            breaks = []
            for pattern in patterns:
                for match in re.finditer(pattern, text):
                    breaks.append(match.start())
            return sorted(set(breaks))

        def split_on_sentences(text: str, target_size: int = 4000, max_size: int = 6000, overlap: int = 250) -> list:
            # Find sentence boundaries
            sentence_ends = []
            for match in re.finditer(r'[.!?]\\s+[A-Z]', text):
                sentence_ends.append(match.start() + 1)  # Position after punctuation
            
            if not sentence_ends:
                # Fallback to word boundaries if no sentences found
                words = text.split()
                chunks = []
                current_chunk = []
                current_size = 0
                
                for word in words:
                    word_size = len(word) + 1
                    if current_size + word_size > target_size and current_chunk:
                        chunk_text = ' '.join(current_chunk)
                        chunks.append(chunk_text)
                        # Add overlap
                        overlap_words = current_chunk[-20:] if len(current_chunk) > 20 else current_chunk
                        current_chunk = overlap_words + [word]
                        current_size = sum(len(w) + 1 for w in current_chunk)
                    else:
                        current_chunk.append(word)
                        current_size += word_size
                
                if current_chunk:
                    chunks.append(' '.join(current_chunk))
                return chunks if chunks else [text]
            
            # Split on sentence boundaries
            chunks = []
            start = 0
            
            for end_pos in sentence_ends:
                if end_pos - start >= target_size:
                    # Create chunk up to this sentence boundary
                    chunk_text = text[start:end_pos].strip()
                    if chunk_text:
                        chunks.append(chunk_text)
                    
                    # Start next chunk with overlap
                    overlap_start = max(start, end_pos - overlap)
                    start = overlap_start
            
            # Add remaining text
            if start < len(text):
                remaining = text[start:].strip()
                if remaining:
                    chunks.append(remaining)
            
            return chunks if chunks else [text]

        def smart_chunk_transcript(text: str, target_size: int = 4000, max_size: int = 6000) -> list:
            # First try natural breaks
            natural_breaks = find_natural_breaks(text)
            
            if len(natural_breaks) >= 2:  # At least 2 natural breaks found
                chunks = []
                start = 0
                
                for break_pos in natural_breaks:
                    if break_pos - start >= target_size:
                        chunk_text = text[start:break_pos].strip()
                        if chunk_text:
                            chunks.append(chunk_text)
                        start = break_pos
                
                # Add remaining text
                if start < len(text):
                    remaining = text[start:].strip()
                    if remaining:
                        chunks.append(remaining)
                
                # Check if chunks are reasonable size
                oversized_chunks = []
                for chunk in chunks:
                    if len(chunk) > max_size:
                        # Further split oversized chunks
                        oversized_chunks.extend(split_on_sentences(chunk, target_size, max_size))
                    else:
                        oversized_chunks.append(chunk)
                
                return oversized_chunks if oversized_chunks else [text]
            
            # Fallback to sentence-based splitting
            return split_on_sentences(text, target_size, max_size)

        def enhanced_pretag(text: str, content_type: str) -> str:
            blocks = text.split("\\n\\n")
            out = []
            
            # Content-type specific protection patterns
            EDUCATION_PROTECT = [
                r"(?i)\b(?:dave|randy|eric)\b.*?(?:story|transformation|journey|experience)",  # Personal stories
                r"(?i)\b(?:framework|system|method|approach|strategy|model|process)\b",  # Frameworks
                r"(?i)\b(?:misconception|belief|mindset|habit|action)s?\b",  # Key concepts
                r"(?i)\b(?:leverage|profit|time|team|system|dashboard)\s+(?:point|lever)\b",  # Leverage points
                r"\b\d+\s*(?:million|years?|months?|%|\$)",  # Key numbers
            ]
            
            CASE_STUDY_PAT = re.compile(r"(?i)\b(?:dave|case study|transformation|went from|results?)\b")
            
            for b in blocks:
                score = 0
                
                # Original scoring
                if QA_PAT.search(b): score += 3  # Q&A is critical
                if NUM_PAT.search(b): score += 2  # Numbers important 
                if FRAME_PAT.search(b): score += 1  # Lists
                if NAME_FRAME_PAT.search(b): score += 1  # Named frameworks
                
                # Content-type specific scoring
                if content_type == "education":
                    if CASE_STUDY_PAT.search(b): score += 3  # Case studies critical
                    for pattern in EDUCATION_PROTECT:
                        if re.search(pattern, b): score += 2
                        
                # Tag high-value blocks for protection
                if score >= 2:  # Lower threshold for education
                    tag_type = "CRITICAL" if score >= 4 else "IMPORTANT"
                    out.append(f"[[KEEP:{tag_type}]]\\n{b}\\n[[/KEEP]]")
                else:
                    out.append(b)
                    
            return "\\n\\n".join(out)

        def pretag(text: str) -> str:
            # Backward compatibility - default to education protection
            return enhanced_pretag(text, "education")

        def word_count(s: str) -> int:
            return len(re.findall(r"\w+", s))

        def chat_once(model: str, system_prompt: str, user_prompt: str, host: str, temperature: float, top_p: float, retries: int = 3, timeout: float = 180.0) -> str:
            url = host.rstrip("/") + "/api/chat"
            payload = {"model": model, "messages": [{"role":"system","content":system_prompt},{"role":"user","content":user_prompt}], "options":{"temperature":temperature,"top_p":top_p}, "stream": False}
            backoff = 1.0; last = None
            for _ in range(retries):
                try:
                    r = requests.post(url, json=payload, timeout=timeout)
                    r.raise_for_status()
                    data = r.json()
                    return data.get("message", {}).get("content", "")
                except Exception as e:
                    last = e; time.sleep(backoff); backoff = min(backoff*2, 8.0)
            raise RuntimeError(f"Ollama chat failed: {last}")

        def iter_chunks(text: str, size: int = 7000, overlap: int = 500):
            """Split text into overlapping chunks"""
            i = 0
            n = len(text)
            while i < n:
                j = min(n, i + size)
                yield text[i:j]
                i = j - overlap
        
        def atomic_write_text(p: Path, s: str):
            """Atomic write to prevent partial files"""
            tmp = p.with_suffix(p.suffix + ".tmp")
            with open(tmp, "w", encoding="utf-8") as f:
                f.write(s)
                f.flush()
                os.fsync(f.fileno())
            os.replace(tmp, p)
        
        def jlog(logpath: Path, event: str, **kw):
            """Simple JSONL logger for debugging"""
            rec = {"ts": time.time(), "event": event}
            rec.update(kw)
            with open(logpath, "a", encoding="utf-8") as f:
                f.write(json.dumps(rec, ensure_ascii=False) + "\\n")

        # Improved Q&A detection patterns
        QUESTION_LEADS = re.compile(r"(^|\\n)(?:[A-Z][a-z]+:)?\\s*(how|what|why|when|where|which|can|should|could|would|do|does|did)\\b.*\\?\\s*$", re.IGNORECASE|re.MULTILINE)
        SPEAKER_LINE = re.compile(r"^\\s*([A-Z][a-zA-Z]+):\\s+", re.MULTILINE)

        def heuristic_qa(text: str) -> List[Dict[str, str]]:
            """Heuristic Q&A detection before LLM processing"""
            qas = []
            for m in QUESTION_LEADS.finditer(text):
                q_start = m.start()
                q_end = m.end()
                # Naive answer = next 1-3 paragraphs
                after = text[q_end:]
                ans = after.split("\\n\\n", 3)
                answer = "\\n\\n".join(ans[:2]).strip()
                speaker = None
                sp = SPEAKER_LINE.search(text[max(0, q_start-120):q_start])
                if sp:
                    speaker = sp.group(1)
                qas.append({
                    "question": text[q_start:q_end].strip(),
                    "answer": answer,
                    "speaker": speaker,
                    "position": q_start
                })
            return qas

        def naive_section_map(text: str) -> List[Dict[str, Any]]:
            """Generate section map for downstream tools"""
            out = []
            words = re.findall(r"\\w+", text)
            pos = 0
            for ln in text.splitlines():
                if ln.startswith("## "):
                    title = ln[3:].strip()
                    anchor = "#" + re.sub(r'[^a-z0-9\\-]+', '-', title.lower()).strip("-")
                    out.append({
                        "title": title,
                        "anchor": anchor,
                        "start_word": len(words[:pos])
                    })
                pos += len(ln.split())
            # Approximate end_word by next start
            for i in range(len(out)-1):
                out[i]["end_word"] = out[i+1]["start_word"]
            if out:
                out[-1]["end_word"] = len(words)
            return out
        
        def generate_toc(text: str, model: str, host: str) -> str:
            """Generate table of contents from text"""
            try:
                parts = []
                toc_prompt = PROMPTS["education"]["toc"]
                for chunk in iter_chunks(text):
                    parts.append(chat_once(model=model, system_prompt=toc_prompt, user_prompt=chunk, host=host, temperature=0.1, top_p=0.9))
                # Simple de-dup/merge of headings
                seen = set()
                lines = []
                for p in parts:
                    for ln in p.splitlines():
                        if ln.strip().startswith(("#", "-", "*")) and ln not in seen:
                            seen.add(ln)
                            lines.append(ln)
                return "\\n".join(lines).strip() or "# Table of Contents\\n\\n(none)"
            except Exception as e:
                print(f"Warning: TOC generation failed: {e}", file=sys.stderr)
                return "# Table of Contents\\n\\n(failed)"

        def generate_section_capsules(text: str, model: str, host: str) -> str:
            """Generate brief capsules for major sections"""
            try:
                parts = []
                nav_prompt = PROMPTS["education"]["navigation"]
                for chunk in iter_chunks(text):
                    parts.append(chat_once(model=model, system_prompt=nav_prompt, user_prompt=chunk, host=host, temperature=0.1, top_p=0.9))
                return "\\n\\n".join(parts).strip()
            except Exception as e:
                print(f"Warning: Section capsule generation failed: {e}", file=sys.stderr)
                return "Section capsule generation failed"

        def extract_qa_pairs(text: str, model: str, host: str) -> List[Dict[str, str]]:
            """Extract Q&A pairs as structured data"""
            try:
                # First try heuristic detection
                fallback = heuristic_qa(text)
                if fallback:
                    return fallback
                
                # If no heuristic matches, try LLM extraction
                qa_prompt = PROMPTS["education"]["extract_qa"]
                qa_json = chat_once(model=model, system_prompt=qa_prompt, user_prompt=text, host=host, temperature=0.0, top_p=0.9)
                # Try to parse JSON, fallback to regex extraction if fails
                try:
                    return json.loads(qa_json)
                except:
                    # Final fallback: simple regex extraction
                    qa_pairs = []
                    qa_matches = QA_PAT.findall(text)
                    for i, match in enumerate(qa_matches):
                        qa_pairs.append({"id": i+1, "type": "qa", "content": match})
                    return qa_pairs
            except Exception as e:
                print(f"Warning: Q&A extraction failed: {e}", file=sys.stderr)
                return []

        def extract_numbers(text: str, model: str, host: str) -> List[Dict[str, str]]:
            """Extract numbers and metrics as structured data"""
            try:
                num_prompt = PROMPTS["education"]["extract_numbers"]
                numbers_json = chat_once(model=model, system_prompt=num_prompt, user_prompt=text, host=host, temperature=0.0, top_p=0.9)
                try:
                    return json.loads(numbers_json)
                except:
                    # Fallback: regex extraction with better labeling
                    numbers = []
                    label_keywords = {
                        "revenue": ["revenue", "sales", "income", "dollars", "$"],
                        "headcount": ["team", "people", "employees", "staff"],
                        "time": ["years", "months", "weeks", "days", "hours"],
                        "percentage": ["%", "percent", "rate"]
                    }
                    for i, match in enumerate(NUM_PAT.finditer(text)):
                        context_window = text[max(0, match.start()-100):match.end()+100].lower()
                        label = "metric"
                        for label_type, keywords in label_keywords.items():
                            if any(kw in context_window for kw in keywords):
                                label = label_type
                                break
                        numbers.append({
                            "id": i+1,
                            "number": match.group(0),
                            "position": match.start(),
                            "context": text[max(0, match.start()-100):match.end()+100],
                            "label": label
                        })
                    return numbers
            except Exception as e:
                print(f"Warning: Number extraction failed: {e}", file=sys.stderr)
                return []

        def extract_frameworks(text: str, model: str, host: str) -> List[Dict[str, str]]:
            """Extract frameworks and methodologies as structured data"""
            try:
                fw_prompt = PROMPTS["education"]["extract_frameworks"]
                frameworks_json = chat_once(model=model, system_prompt=fw_prompt, user_prompt=text, host=host, temperature=0.0, top_p=0.9)
                try:
                    return json.loads(frameworks_json)
                except:
                    # Fallback: regex extraction of named frameworks
                    frameworks = []
                    for i, match in enumerate(NAME_FRAME_PAT.finditer(text)):
                        frameworks.append({
                            "id": i+1,
                            "name": match.group(0),
                            "position": match.start(),
                            "context": text[max(0, match.start()-100):match.end()+100]
                        })
                    return frameworks
            except Exception as e:
                print(f"Warning: Framework extraction failed: {e}", file=sys.stderr)
                return []

        def validate_content_coverage(original: str, processed: str, content_type: str) -> Dict[str, Any]:
            """Validate that critical content wasn't lost during processing"""
            validation_results = {"passed": True, "warnings": [], "metrics": {}}
            
            if content_type == "education":
                # Check number preservation
                original_numbers = len(NUM_PAT.findall(original))
                processed_numbers = len(NUM_PAT.findall(processed))
                number_retention = processed_numbers / max(1, original_numbers)
                validation_results["metrics"]["number_retention"] = round(number_retention, 3)
                
                if number_retention < 0.9:  # Lost >10% of numbers
                    validation_results["warnings"].append(f"Number loss: {processed_numbers}/{original_numbers} retained ({number_retention:.1%})")
                    if number_retention < 0.8:
                        validation_results["passed"] = False
                
                # Check Q&A preservation
                original_qa = len(QA_PAT.findall(original))
                processed_qa = len(QA_PAT.findall(processed))
                qa_retention = processed_qa / max(1, original_qa) if original_qa > 0 else 1.0
                validation_results["metrics"]["qa_retention"] = round(qa_retention, 3)
                
                if qa_retention < 0.9 and original_qa > 0:
                    validation_results["warnings"].append(f"Q&A loss: {processed_qa}/{original_qa} retained ({qa_retention:.1%})")
                    if qa_retention < 0.8:
                        validation_results["passed"] = False
                
                # Check framework mentions
                original_frameworks = len(NAME_FRAME_PAT.findall(original))
                processed_frameworks = len(NAME_FRAME_PAT.findall(processed))
                fw_retention = processed_frameworks / max(1, original_frameworks) if original_frameworks > 0 else 1.0
                validation_results["metrics"]["framework_retention"] = round(fw_retention, 3)
                
                if fw_retention < 0.8 and original_frameworks > 0:
                    validation_results["warnings"].append(f"Framework loss: {processed_frameworks}/{original_frameworks} retained ({fw_retention:.1%})")
            
            return validation_results

        def generate_yaml_frontmatter(src: Path, content_type: str, word_count_in: int, word_count_out: int, retain_ratio: float, **kwargs) -> str:
            """Generate YAML front-matter for the document"""
            frontmatter = {
                "title": src.stem,
                "source_file": str(src),
                "content_type": content_type,
                "processing_date": datetime.now(timezone.utc).isoformat(),
                "word_count_original": word_count_in,
                "word_count_processed": word_count_out,
                "retention_ratio": round(retain_ratio, 3),
                "processing_mode": "navigation_layer"
            }
            frontmatter.update(kwargs)
            if HAS_YAML:
                return "---\n" + yaml.safe_dump(frontmatter, sort_keys=False, allow_unicode=True) + "---\n\n"
            else:
                # Fallback to JSON front-matter if YAML not available
                return "```json\n" + json.dumps(frontmatter, indent=2, ensure_ascii=False) + "\n```\n\n"

        def detect_content_type(text: str, src_path: Path) -> str:
            # Check folder path for hints
            path_lower = str(src_path).lower()
            if any(word in path_lower for word in ['education', 'webinar', 'seminar', 'training', 'course']):
                return "education"
            if any(word in path_lower for word in ['meeting', 'standup', 'sync']):
                return "meeting"
            if any(word in path_lower for word in ['podcast', 'interview', 'episode']):
                return "podcast"
            
            # Content-based detection
            education_score = sum(1 for pattern in EDUCATION_PATTERNS if re.search(pattern, text[:5000]))
            meeting_score = sum(1 for pattern in MEETING_PATTERNS if re.search(pattern, text[:5000]))
            podcast_score = sum(1 for pattern in PODCAST_PATTERNS if re.search(pattern, text[:5000]))
            
            if education_score >= 2:
                return "education"
            elif meeting_score >= 2:
                return "meeting"
            elif podcast_score >= 2:
                return "podcast"
            else:
                return "default"

        def process_file(src: Path, dst_dir: Path, model: str, host: str, temperature: float, top_p: float, force: bool, mode: str = "preserve-education", min_retain: float = 0.60, append_full: bool = True) -> Path:
            # Create navigation layer output structure
            body_dir = dst_dir / "body"
            navigation_dir = dst_dir / "navigation"
            extracts_dir = dst_dir / "extracts"
            metadata_dir = dst_dir / "metadata"
            
            for dir_path in [body_dir, navigation_dir, extracts_dir, metadata_dir]:
                dir_path.mkdir(parents=True, exist_ok=True)
            
            # Output paths
            body_dst = body_dir / src.name
            nav_dst = navigation_dir / src.name
            meta_dst = metadata_dir / f"{src.stem}.yaml"
            sidecar_dst = metadata_dir / f"{src.stem}.json"
            
            # Primary output is body (cleaned content)
            dst = body_dst
            
            if dst.exists() and not force:
                return dst
                
            raw = src.read_text(encoding="utf-8", errors="ignore")
            word_count_in = word_count(raw)
            
            # Detect content type
            content_type = detect_content_type(raw, src)
            print(f"Detected content type: {content_type} for {src.name}", file=sys.stderr)
            
            # Step 1: Clean the content (minimal processing)
            cleaned = strip_filler(raw)
            word_count_out = word_count(cleaned)
            retain_ratio = word_count_out / max(1, word_count_in)
            
            # For education content, use navigation layer approach
            if content_type == "education" and mode == "preserve-education":
                print(f"Using navigation layer approach for {src.name}", file=sys.stderr)
                
                # Validate content coverage before saving
                validation = validate_content_coverage(raw, cleaned, content_type)
                for warning in validation["warnings"]:
                    print(f"VALIDATION WARNING: {warning}", file=sys.stderr)
                if not validation["passed"]:
                    print(f"VALIDATION FAILED: Critical content loss detected", file=sys.stderr)
                
                # Save cleaned body (main content) with atomic write
                frontmatter = generate_yaml_frontmatter(src, content_type, word_count_in, word_count_out, retain_ratio, 
                                                       validation_passed=validation["passed"], validation_metrics=validation["metrics"])
                body_content = frontmatter + cleaned.strip()
                atomic_write_text(body_dst, body_content)
                print(f"Body content saved: {body_dst.name} ({word_count_out} words, {retain_ratio:.1%} retention)", file=sys.stderr)
                
                # Generate navigation layer
                try:
                    toc = generate_toc(cleaned, model, host)
                    capsules = generate_section_capsules(cleaned, model, host)
                    section_map = naive_section_map(cleaned)
                    
                    # Write navigation markdown
                    nav_content = f"# Navigation for {src.stem}\\n\\n"
                    nav_content += f"## Table of Contents\\n\\n{toc}\\n\\n"
                    nav_content += f"## Section Capsules\\n\\n{capsules}\\n\\n"
                    atomic_write_text(nav_dst, nav_content)
                    
                    # Write section map JSON
                    section_json_path = navigation_dir / f"{src.stem}_sections.json"
                    atomic_write_text(section_json_path, json.dumps(section_map, indent=2))
                    
                    # Write standalone YAML metadata file
                    meta_data = {
                        "title": src.stem,
                        "content_type": content_type,
                        "processing_mode": "navigation_layer",
                        "word_count_original": word_count_in,
                        "word_count_processed": word_count_out,
                        "retention_ratio": round(retain_ratio, 3),
                        "validation_passed": validation["passed"],
                        "validation_metrics": validation["metrics"],
                        "section_count": len(section_map),
                        "timestamp": datetime.now(timezone.utc).isoformat()
                    }
                    if HAS_YAML:
                        yaml_meta = yaml.safe_dump(meta_data, sort_keys=False, allow_unicode=True)
                    else:
                        yaml_meta = json.dumps(meta_data, indent=2, ensure_ascii=False)
                    # Write as YAML or JSON based on availability
                    if not HAS_YAML:
                        meta_dst = meta_dst.with_suffix(".json")
                    atomic_write_text(meta_dst, yaml_meta)
                    
                    print(f"Navigation layer saved: {nav_dst.name}, {section_json_path.name}, {meta_dst.name}", file=sys.stderr)
                except Exception as e:
                    print(f"Warning: Navigation generation failed: {e}", file=sys.stderr)
                
                # Setup logging
                log_file = metadata_dir / f"{src.stem}.log"
                jlog(log_file, "extract_start", file=src.name)
                
                # Generate extracts
                try:
                    # Q&A extraction
                    qa_pairs = extract_qa_pairs(cleaned, model, host)
                    if qa_pairs:
                        qa_file = extracts_dir / f"{src.stem}_qa.json"
                        atomic_write_text(qa_file, json.dumps(qa_pairs, indent=2))
                        jlog(log_file, "qa_extracted", count=len(qa_pairs))
                        print(f"Q&A extracted: {len(qa_pairs)} pairs -> {qa_file.name}", file=sys.stderr)
                    
                    # Numbers extraction
                    numbers = extract_numbers(cleaned, model, host)
                    if numbers:
                        # Write JSON
                        numbers_file = extracts_dir / f"{src.stem}_numbers.json"
                        atomic_write_text(numbers_file, json.dumps(numbers, indent=2))
                        
                        # Also write CSV
                        csv_path = extracts_dir / f"{src.stem}_numbers.csv"
                        with open(csv_path, "w", newline="", encoding="utf-8") as f:
                            if numbers:
                                fieldnames = list(numbers[0].keys())
                                w = csv.DictWriter(f, fieldnames=fieldnames)
                                w.writeheader()
                                w.writerows(numbers)
                        
                        jlog(log_file, "numbers_extracted", count=len(numbers))
                        print(f"Numbers extracted: {len(numbers)} entries -> {numbers_file.name}, {csv_path.name}", file=sys.stderr)
                    
                    # Frameworks extraction
                    frameworks = extract_frameworks(cleaned, model, host)
                    if frameworks:
                        fw_file = extracts_dir / f"{src.stem}_frameworks.json"
                        atomic_write_text(fw_file, json.dumps(frameworks, indent=2))
                        jlog(log_file, "frameworks_extracted", count=len(frameworks))
                        print(f"Frameworks extracted: {len(frameworks)} items -> {fw_file.name}", file=sys.stderr)
                        
                except Exception as e:
                    jlog(log_file, "extract_failed", error=str(e))
                    print(f"Warning: Extract generation failed: {e}", file=sys.stderr)
                
                # Create JSON sidecar with metadata
                sidecar_data = {
                    "source": str(src),
                    "content_type": content_type,
                    "processing_mode": "navigation_layer",
                    "word_count_original": word_count_in,
                    "word_count_processed": word_count_out,
                    "retention_ratio": round(retain_ratio, 3),
                    "outputs": {
                        "body": str(body_dst),
                        "navigation": str(nav_dst) if nav_dst.exists() else None,
                        "extracts": {
                            "qa": str(extracts_dir / f"{src.stem}_qa.json") if (extracts_dir / f"{src.stem}_qa.json").exists() else None,
                            "numbers": str(extracts_dir / f"{src.stem}_numbers.json") if (extracts_dir / f"{src.stem}_numbers.json").exists() else None,
                            "frameworks": str(extracts_dir / f"{src.stem}_frameworks.json") if (extracts_dir / f"{src.stem}_frameworks.json").exists() else None
                        }
                    },
                    "timestamp": datetime.now(timezone.utc).isoformat()
                }
                atomic_write_text(sidecar_dst, json.dumps(sidecar_data, indent=2))
                jlog(log_file, "processing_complete", output=str(body_dst))
                print(f"Sidecar metadata saved: {sidecar_dst.name}", file=sys.stderr)
                
                return body_dst
            
            # Handle cleanup-only mode or non-education content
            else:
                print(f"Using traditional processing for {content_type} content", file=sys.stderr)
                frontmatter = generate_yaml_frontmatter(src, content_type, word_count_in, word_count_out, retain_ratio, mode=mode)
                final_content = frontmatter + cleaned.strip() + "\\n"
                atomic_write_text(body_dst, final_content)
                
                # Simple metadata for non-education content
                sidecar_data = {
                    "source": str(src),
                    "content_type": content_type, 
                    "processing_mode": mode,
                    "word_count_original": word_count_in,
                    "word_count_processed": word_count_out,
                    "retention_ratio": round(retain_ratio, 3),
                    "timestamp": datetime.now(timezone.utc).isoformat()
                }
                atomic_write_text(sidecar_dst, json.dumps(sidecar_data, indent=2))
                return body_dst

        def main():
            ap = argparse.ArgumentParser()
            ap.add_argument("--input", "-i", default=os.environ.get("TRANSCRIPTS_INPUT", "${inputDirDefault}"))
            ap.add_argument("--output", "-o", default=os.environ.get("TRANSCRIPTS_OUTPUT", "${outputDirDefault}"))
            ap.add_argument("--pattern", "-p", default="*.md")
            ap.add_argument("--model", "-m", default=os.environ.get("OLLAMA_MODEL", "${cfg.model}"))
            ap.add_argument("--host", default=os.environ.get("OLLAMA_HOST", "${cfg.host}"))
            ap.add_argument("--force", "-f", action="store_true")
            ap.add_argument("--temperature", type=float, default=float(os.environ.get("OLLAMA_TEMPERATURE", "0.1")))
            ap.add_argument("--top_p", type=float, default=float(os.environ.get("OLLAMA_TOP_P", "0.9")))
            ap.add_argument("--mode", choices=["cleanup-only","preserve-education","summary-mode"], default=os.environ.get("FORMATTER_MODE","preserve-education"))
            ap.add_argument("--min-retain", type=float, default=float(os.environ.get("MIN_RETAIN_RATIO","0.60")))
            ap.add_argument("--append-full", type=int, default=int(os.environ.get("APPEND_FULL","1")))
            args = ap.parse_args()
            in_dir = Path(args.input); out_dir = Path(args.output); out_dir.mkdir(parents=True, exist_ok=True)
            files = sorted(in_dir.glob(args.pattern))
            if not files:
                print(f"No files matching {args.pattern} in {in_dir}", file=sys.stderr); sys.exit(1)
            errors = 0
            for path in files:
                try:
                    process_file(path, out_dir, args.model, args.host, args.temperature, args.top_p, args.force, mode=args.mode, min_retain=args.min_retain, append_full=bool(args.append_full))
                except Exception as e:
                    errors += 1; print(f"[ERROR] {path.name}: {e}", file=sys.stderr)
            sys.exit(1 if errors else 0)

        if __name__ == "__main__":
            main()
      '';
      executable = true;
    };

    home.file.".local/bin/transcript-formatter".text = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec python3 ${scriptPath} "$@"
    '';
    home.file.".local/bin/transcript-formatter".executable = true;

    systemd.user.services.transcript-formatter = {
      Unit.Description = "Transcript formatter using local Ollama";
      Service = {
        Type = "simple";
        Environment = [
          "TRANSCRIPTS_INPUT=${cfg.inputDir}"
          "TRANSCRIPTS_OUTPUT=${cfg.outputDir}"
          "OLLAMA_HOST=${cfg.host}"
          "OLLAMA_MODEL=${cfg.model}"
          "OLLAMA_TEMPERATURE=0.1"
          "OLLAMA_TOP_P=0.9"
          "FORMATTER_MODE=${cfg.mode}"
          "MIN_RETAIN_RATIO=${builtins.toString cfg.minRetainRatio}"
          "APPEND_FULL=${if cfg.appendFull then "1" else "0"}"
          "PATH=${config.home.profileDirectory}/bin"
        ];
        ExecStart = "%h/.local/bin/transcript-formatter";
        WorkingDirectory = "%h";
      };
      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.timers.transcript-formatter = {
      Unit.Description = "Run transcript formatter periodically";
      Timer = {
        OnBootSec = "2m";
        OnUnitActiveSec = cfg.interval;
        Persistent = true;
      };
      Install.WantedBy = [ "timers.target" ];
    };
  };
}
