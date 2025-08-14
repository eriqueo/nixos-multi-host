# Jellyfin GPU Hardware Acceleration Setup Guide

## Overview

This guide covers setting up NVIDIA GPU hardware acceleration for Jellyfin on NixOS, specifically for the NVIDIA Quadro P1000 and similar Pascal-generation GPUs.

## Hardware Capabilities

### NVIDIA Quadro P1000 (GP107 Pascal Architecture)

**Specifications:**
- 512 CUDA cores
- 4GB GDDR5 VRAM
- Pascal GP107 chip (14nm process)
- Third-generation NVENC/NVDEC

**Hardware Encoding (NVENC) Support:**
- **H.264**: Full support with B-frames, up to 4K@60fps
- **H.265/HEVC**: Supported but NO B-frames (I and P frames only)
  - Max CTU size: 32 (vs HEVC standard of 64)
  - Min CTU size: 8
  - No Sample Adaptive Offset (SAO)
- **AV1**: Supported (requires newer drivers)

**Hardware Decoding (NVDEC) Support:**
- H.264, H.265/HEVC, VP8, VP9
- MPEG-1, MPEG-2, MPEG-4, VC1
- Some VP9 10-bit support

**Concurrent Encoding Limitations:**
- **2 simultaneous encoding sessions maximum** (same as GeForce cards)
- Higher-end Quadro cards (P2000+) have unlimited sessions

## Current System Analysis

### GPU Status Check
```bash
# Check GPU presence
lspci | grep -i vga
# Should show: NVIDIA Corporation GP107GL [Quadro P1000]

# Check NVIDIA driver status
sudo nvidia-smi

# Check loaded kernel modules
lsmod | grep nvidia
```

### FFmpeg Capabilities
Your Jellyfin installation includes proper NVENC/NVDEC support:

```bash
# Check hardware acceleration methods
/nix/store/fvr78yr36anl4h054ph6nz3jpsdm7ank-jellyfin-ffmpeg-7.1.1-6-bin/bin/ffmpeg -hwaccels
# Shows: vdpau, cuda, vaapi, qsv, drm, opencl, vulkan

# Available NVIDIA encoders
ffmpeg -encoders | grep nvenc
# h264_nvenc, hevc_nvenc, av1_nvenc

# Available NVIDIA decoders  
ffmpeg -decoders | grep cuvid
# h264_cuvid, hevc_cuvid, av1_cuvid, etc.
```

## Current Jellyfin Configuration Issues

**Problem**: Your current `/var/lib/jellyfin/config/encoding.xml` has:
```xml
<HardwareAccelerationType>none</HardwareAccelerationType>
```

**Solution**: Change to:
```xml
<HardwareAccelerationType>nvenc</HardwareAccelerationType>
```

## Configuration Steps

### 1. Backup Current Configuration
```bash
sudo cp /var/lib/jellyfin/config/encoding.xml /var/lib/jellyfin/config/encoding.xml.backup
```

### 2. Enable NVIDIA Hardware Acceleration

Edit `/var/lib/jellyfin/config/encoding.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<EncodingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <!-- CRITICAL: Change from 'none' to 'nvenc' -->
  <HardwareAccelerationType>nvenc</HardwareAccelerationType>
  
  <!-- Enable hardware encoding -->
  <EnableHardwareEncoding>true</EnableHardwareEncoding>
  
  <!-- Enhanced NVDEC decoder (recommended for Pascal+) -->
  <EnableEnhancedNvdecDecoder>true</EnableEnhancedNvdecDecoder>
  
  <!-- Hardware decoding codecs -->
  <HardwareDecodingCodecs>
    <string>h264</string>
    <string>vc1</string>
    <string>hevc</string>
    <string>vp8</string>
    <string>vp9</string>
  </HardwareDecodingCodecs>
  
  <!-- Allow HEVC encoding (optional, quality may vary) -->
  <AllowHevcEncoding>true</AllowHevcEncoding>
  
  <!-- Threading: -1 = auto, or set to number of CPU cores -->
  <EncodingThreadCount>-1</EncodingThreadCount>
  
  <!-- Other existing settings... -->
</EncodingOptions>
```

### 3. Verify Jellyfin User GPU Access

Ensure the `jellyfin` user can access the GPU:

```bash
# Check device permissions
ls -la /dev/nvidia*
ls -la /dev/dri/

# Add jellyfin user to video group if needed
sudo usermod -a -G video jellyfin
```

### 4. Restart Jellyfin Service

```bash
sudo systemctl restart jellyfin
```

### 5. Verify GPU Usage

After restarting, monitor GPU usage during transcoding:

```bash
# Watch GPU utilization in real-time
watch -n 1 'sudo nvidia-smi'

# Check Jellyfin logs for hardware acceleration
sudo journalctl -u jellyfin -f | grep -i "nvenc\|nvdec\|cuda"
```

## Performance Optimization

### Recommended Settings

**For H.264 Encoding:**
- CRF: 23 (good quality/size balance)
- Preset: `medium` or `fast`
- Profile: `high`

**For H.265 Encoding:**
- CRF: 28 (higher values due to better compression)
- Note: Limited to I and P frames only on P1000

### Concurrent Session Limits

- **Maximum 2 simultaneous hardware transcodes**
- Additional sessions will fall back to CPU encoding
- Plan accordingly for multiple users

## Troubleshooting

### Common Issues

1. **"NVENC not available" errors:**
   ```bash
   # Check if nvidia-ml-py is available
   python3 -c "import pynvml; print('NVML available')" 2>/dev/null || echo "NVML not available"
   ```

2. **Permission denied errors:**
   ```bash
   # Verify jellyfin user group membership
   groups jellyfin
   # Should include 'video' group
   ```

3. **No hardware acceleration in logs:**
   ```bash
   # Test hardware encoding manually
   /nix/store/.../ffmpeg -f lavfi -i testsrc=duration=10:size=1280x720:rate=30 \
     -c:v h264_nvenc -preset fast -crf 23 test_output.mp4
   ```

### Performance Monitoring

```bash
# Monitor during transcoding
sudo nvidia-smi dmon -s puc

# Check encoding sessions
sudo nvidia-smi -q -d encoder

# Monitor system load
htop
```

## NixOS-Specific Configuration

### Hardware Configuration

Ensure your NixOS configuration includes:

```nix
# hardware-configuration.nix or relevant module
hardware.opengl = {
  enable = true;
  driSupport = true;
  driSupport32Bit = true;
};

# NVIDIA drivers
services.xserver.videoDrivers = [ "nvidia" ];
hardware.nvidia = {
  modesetting.enable = true;
  open = false;  # Use proprietary driver for better NVENC support
  nvidiaSettings = true;
};
```

### Jellyfin Service Configuration

```nix
# In your NixOS configuration
services.jellyfin = {
  enable = true;
  openFirewall = true;
  group = "jellyfin";
};

# Ensure video group access
users.groups.jellyfin = {};
users.users.jellyfin = {
  isSystemUser = true;
  group = "jellyfin";
  extraGroups = [ "video" ];
};
```

## Performance Expectations

### Transcoding Capacity (Quadro P1000)

- **1x 4K@60fps** H.264/H.265 stream
- **4x 1080p@60fps** H.264/H.265 streams  
- **8x 1080p@30fps** H.264/H.265 streams
- **2 concurrent encoding sessions maximum**

### Quality Considerations

- **H.264 NVENC**: Very good quality, close to x264 `fast` preset
- **H.265 NVENC**: Decent quality but no B-frames limits efficiency
- **CPU vs GPU**: GPU encoding trades some quality for speed/efficiency

## Best Practices

1. **Enable hardware decoding first** - lower impact, immediate benefits
2. **Test encoding settings** - balance quality vs performance
3. **Monitor GPU utilization** - ensure you're actually using hardware acceleration
4. **Plan for session limits** - 2 concurrent encodes maximum
5. **Keep drivers updated** - newer NVIDIA drivers improve NVENC quality

## Future Upgrades

For better NVENC performance, consider upgrading to:
- **RTX 4000 series**: Dual AV1 encoders, unlimited sessions
- **RTX A4000+**: Professional cards with unlimited concurrent sessions
- **Modern Quadro**: Better HEVC B-frame support

## Additional Resources

- [NVIDIA Video Codec SDK Documentation](https://developer.nvidia.com/video-codec-sdk)
- [Jellyfin Hardware Acceleration Guide](https://jellyfin.org/docs/general/administration/hardware-acceleration/)
- [FFmpeg NVENC Documentation](https://trac.ffmpeg.org/wiki/HWAccelIntro)

---

**Last Updated**: 2025-08-02  
**Hardware**: NVIDIA Quadro P1000  
**OS**: NixOS  
**Jellyfin Version**: 10.10.7