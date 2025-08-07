# YouTube Transcript API - Mobile Integration Guide

## System Overview

The YouTube Transcript API provides a REST interface for extracting transcripts from YouTube videos and playlists, designed for integration with iOS Shortcuts and Android automation.

## API Endpoints

- **Base URL**: `http://[tailscale-ip]:8099` or `http://[local-ip]:8099`
- **Authentication**: `x-api-key` header (configure via API_KEYS environment variable)

### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/transcript` | Submit video/playlist for processing |
| GET | `/api/status/{request_id}` | Check processing status |
| GET | `/api/download/{request_id}` | Download completed transcripts (ZIP) |
| GET | `/api/list` | List recent requests |
| GET | `/health` | Health check |

## iOS Shortcuts Integration

### 1. Basic YouTube Share Shortcut

**Shortcut Actions:**
1. Get URLs from Input
2. Get Contents of URL (POST to API)
3. Show Notification with result

**Configuration:**
```
URL: http://your-tailscale-ip:8099/api/transcript
Method: POST
Headers: 
  x-api-key: your-api-key-here
  Content-Type: application/json
Request Body (JSON):
{
  "url": "{{URLs}}",
  "format": "standard",
  "languages": ["en", "en-US"]
}
```

### 2. Advanced Shortcut with Status Checking

**Actions:**
1. Get URLs from Input
2. Submit to API (POST /api/transcript)
3. Extract request_id from response
4. Wait 5 seconds
5. Loop: Check status (GET /api/status/{request_id})
6. If complete, download results
7. Save to Files app or share

### 3. Shortcut Template (JSON Export)

```json
{
  "shortcut": {
    "name": "HWC YouTube Transcript",
    "actions": [
      {
        "type": "GetURLsFromInput",
        "uuid": "action1"
      },
      {
        "type": "GetContentsOfURL",
        "uuid": "action2", 
        "url": "http://your-server-ip:8099/api/transcript",
        "method": "POST",
        "headers": {
          "x-api-key": "your-key-here",
          "Content-Type": "application/json"
        },
        "requestBody": {
          "url": "{{action1.output}}",
          "format": "standard",
          "webhook_url": "https://maker.ifttt.com/trigger/transcript_done/with/key/your-ifttt-key"
        }
      },
      {
        "type": "ShowNotification",
        "uuid": "action3",
        "text": "Transcript processing started: {{action2.request_id}}"
      }
    ]
  }
}
```

## Android Integration (Tasker)

### Task: Send YouTube to Transcript API

**Variables:**
- `%TRANSCRIPT_API` = `http://your-server:8099`
- `%API_KEY` = `your-api-key`

**Actions:**
1. **Get Shared Text** → `%youtube_url`
2. **HTTP Request**:
   - URL: `%TRANSCRIPT_API/api/transcript`
   - Method: `POST`
   - Headers: `x-api-key:%API_KEY`
   - Body: `{"url": "%youtube_url", "format": "standard"}`
3. **Parse JSON** → Extract `request_id`
4. **Flash** → "Processing started: %request_id"

## CLI Usage Examples

```bash
# Single video
yt-transcript "https://youtube.com/watch?v=dQw4w9WgXcQ"

# Playlist
yt-transcript "https://youtube.com/playlist?list=PLZHQObOWTQDPD3MizzM2xVFitgF8hE_ab"

# Custom output and format
yt-transcript --output-dir /mnt/hot/custom --format detailed "URL"

# Specific languages
yt-transcript --langs "en,fr,es" "URL"
```

## API Usage Examples

### Submit Request

```bash
curl -X POST http://your-server:8099/api/transcript \
  -H "x-api-key: your-key" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
    "format": "detailed",
    "languages": ["en", "en-US"],
    "webhook_url": "https://your-webhook-url.com/notify"
  }'
```

**Response:**
```json
{
  "request_id": "abc123def456",
  "status": "queued"
}
```

### Check Status

```bash
curl http://your-server:8099/api/status/abc123def456
```

**Response:**
```json
{
  "request_id": "abc123def456",
  "kind": "video",
  "url": "https://youtube.com/watch?v=dQw4w9WgXcQ",
  "status": "complete",
  "progress": 1.0,
  "message": "Video processed successfully",
  "files": ["/mnt/media/transcripts/individual/2025-01-07/never-gonna-give-you-up.md"],
  "created_at": "2025-01-07T10:30:00",
  "updated_at": "2025-01-07T10:31:15"
}
```

### Download Results

```bash
curl -o transcript.zip http://your-server:8099/api/download/abc123def456
```

## Webhook Integration

When processing completes, if `webhook_url` was provided, the API will POST the final status to your webhook:

```json
{
  "request_id": "abc123def456",
  "status": "complete",
  "files": ["/path/to/transcript.md"],
  "message": "Processing completed"
}
```

### IFTTT Integration Example

1. Create IFTTT webhook trigger: `transcript_done`
2. Set webhook URL: `https://maker.ifttt.com/trigger/transcript_done/with/key/YOUR_KEY`
3. Configure action (send email, notification, etc.)

## File Organization

Transcripts are organized as:

```
/mnt/media/transcripts/
├── individual/
│   └── 2025-01-07/
│       └── video-title.md
├── playlists/
│   └── playlist-name/
│       ├── 00-playlist-overview.md
│       └── video-1.md
└── api-requests/
    └── abc123def456/
        ├── status.json
        └── result.zip
```

## Markdown Format

Each transcript includes:

```markdown
# Video Title

## Metadata
- **Channel**: Channel Name
- **Upload Date**: 2025-01-07
- **Duration**: 3m 45s
- **URL**: https://youtube.com/watch?v=...
- **Generated**: 2025-01-07 10:30:15

### 01 ▸ 00:00
Transcript content for first section...

### 02 ▸ 00:23
Next section of transcript...
```

## Rate Limiting

- Default: 10 requests per hour per API key
- Configure with `RATE_LIMIT` environment variable
- Returns 429 status when exceeded

## Security Configuration

Set API keys via environment variable in the NixOS module:

```nix
# In transcript-service.nix, add to serviceEnv:
API_KEYS = "key1,key2,key3";
```

Or use SOPS secrets for production:

```nix
sops.secrets.transcript_api_keys = {
  sopsFile = ../../../secrets/api.yaml;
  key = "transcript/api_keys";
};
```

## Troubleshooting

**Common Issues:**

1. **403 Forbidden** → Check API key in x-api-key header
2. **429 Rate Limited** → Wait or increase RATE_LIMIT setting  
3. **507 Insufficient Storage** → Check disk space, increase FREE_SPACE_GB_MIN
4. **No transcript available** → Video may not have captions enabled

**Logs:**
```bash
# Check API service logs
journalctl -fu podman-transcript-api.service

# Check container logs
podman logs transcript-api
```

**Test API health:**
```bash
curl http://your-server:8099/health
```