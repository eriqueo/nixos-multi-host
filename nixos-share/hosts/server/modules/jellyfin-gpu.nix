# hosts/server/modules/jellyfin-gpu.nix
# Declarative Jellyfin hardware acceleration configuration for NVIDIA Quadro P1000
{ config, lib, pkgs, ... }:

{
  # Override Jellyfin service to enable GPU access
  systemd.services.jellyfin = {
    serviceConfig = {
      # Add GPU device access
      DeviceAllow = [
        "/dev/dri/card0 rw"
        "/dev/dri/card1 rw"
        "/dev/dri/renderD128 rw"
        "/dev/dri/renderD129 rw"
        "/dev/nvidia0 rw"
        "/dev/nvidiactl rw"
        "/dev/nvidia-modeset rw"
        "/dev/nvidia-uvm rw"
        "/dev/nvidia-uvm-tools rw"
      ];
      
      # Add jellyfin user to video group for GPU access
      SupplementaryGroups = [ "video" ];
    };
    
    environment = {
      # NVIDIA GPU acceleration
      NVIDIA_VISIBLE_DEVICES = "all";
      NVIDIA_DRIVER_CAPABILITIES = "compute,video,utility";
      # Critical: Add library path for NVIDIA libraries
      LD_LIBRARY_PATH = "/run/opengl-driver/lib:/run/opengl-driver-32/lib";
    };
  };

  # Create Jellyfin encoding configuration with NVENC enabled
  systemd.services.jellyfin-gpu-config = {
    description = "Configure Jellyfin hardware acceleration";
    before = [ "jellyfin.service" ];
    wantedBy = [ "jellyfin.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
    };
    script = ''
      # Ensure Jellyfin config directory exists
      mkdir -p /var/lib/jellyfin/config
      
      # Create optimized encoding.xml for NVIDIA Quadro P1000
      cat > /var/lib/jellyfin/config/encoding.xml << 'ENCODING_EOF'
<?xml version="1.0" encoding="utf-8"?>
<EncodingOptions xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
  <EncodingThreadCount>-1</EncodingThreadCount>
  <EnableFallbackFont>false</EnableFallbackFont>
  <EnableAudioVbr>false</EnableAudioVbr>
  <DownMixAudioBoost>2</DownMixAudioBoost>
  <DownMixStereoAlgorithm>None</DownMixStereoAlgorithm>
  <MaxMuxingQueueSize>2048</MaxMuxingQueueSize>
  <EnableThrottling>false</EnableThrottling>
  <ThrottleDelaySeconds>180</ThrottleDelaySeconds>
  <EnableSegmentDeletion>false</EnableSegmentDeletion>
  <SegmentKeepSeconds>720</SegmentKeepSeconds>
  
  <\!-- CRITICAL: Enable NVIDIA hardware acceleration -->
  <HardwareAccelerationType>nvenc</HardwareAccelerationType>
  
  <EncoderAppPathDisplay>/nix/store/fvr78yr36anl4h054ph6nz3jpsdm7ank-jellyfin-ffmpeg-7.1.1-6-bin/bin/ffmpeg</EncoderAppPathDisplay>
  <VaapiDevice>/dev/dri/renderD128</VaapiDevice>
  <QsvDevice />
  <EnableTonemapping>false</EnableTonemapping>
  <EnableVppTonemapping>false</EnableVppTonemapping>
  <EnableVideoToolboxTonemapping>false</EnableVideoToolboxTonemapping>
  <TonemappingAlgorithm>bt2390</TonemappingAlgorithm>
  <TonemappingMode>auto</TonemappingMode>
  <TonemappingRange>auto</TonemappingRange>
  <TonemappingDesat>0</TonemappingDesat>
  <TonemappingPeak>100</TonemappingPeak>
  <TonemappingParam>0</TonemappingParam>
  <VppTonemappingBrightness>16</VppTonemappingBrightness>
  <VppTonemappingContrast>1</VppTonemappingContrast>
  <H264Crf>23</H264Crf>
  <H265Crf>28</H265Crf>
  <EncoderPreset xsi:nil="true" />
  <DeinterlaceDoubleRate>false</DeinterlaceDoubleRate>
  <DeinterlaceMethod>yadif</DeinterlaceMethod>
  <EnableDecodingColorDepth10Hevc>true</EnableDecodingColorDepth10Hevc>
  <EnableDecodingColorDepth10Vp9>true</EnableDecodingColorDepth10Vp9>
  <EnableDecodingColorDepth10HevcRext>false</EnableDecodingColorDepth10HevcRext>
  <EnableDecodingColorDepth12HevcRext>false</EnableDecodingColorDepth12HevcRext>
  
  <\!-- Enhanced NVDEC decoder for Pascal architecture -->
  <EnableEnhancedNvdecDecoder>true</EnableEnhancedNvdecDecoder>
  <PreferSystemNativeHwDecoder>true</PreferSystemNativeHwDecoder>
  
  <\!-- Intel acceleration disabled (using NVIDIA) -->
  <EnableIntelLowPowerH264HwEncoder>false</EnableIntelLowPowerH264HwEncoder>
  <EnableIntelLowPowerHevcHwEncoder>false</EnableIntelLowPowerHevcHwEncoder>
  
  <\!-- Enable hardware encoding -->
  <EnableHardwareEncoding>true</EnableHardwareEncoding>
  
  <\!-- Enable HEVC encoding (Pascal supports HEVC but without B-frames) -->
  <AllowHevcEncoding>true</AllowHevcEncoding>
  
  <\!-- AV1 encoding not recommended for Pascal (P1000) -->
  <AllowAv1Encoding>false</AllowAv1Encoding>
  
  <EnableSubtitleExtraction>true</EnableSubtitleExtraction>
  
  <\!-- Hardware decoding codecs supported by Quadro P1000 -->
  <HardwareDecodingCodecs>
    <string>h264</string>
    <string>vc1</string>
    <string>hevc</string>
    <string>vp8</string>
    <string>vp9</string>
    <string>mpeg2</string>
    <string>mpeg4</string>
  </HardwareDecodingCodecs>
  
  <AllowOnDemandMetadataBasedKeyframeExtractionForExtensions>
    <string>mkv</string>
  </AllowOnDemandMetadataBasedKeyframeExtractionForExtensions>
</EncodingOptions>
ENCODING_EOF

      # Set proper ownership and permissions
      chown jellyfin:jellyfin /var/lib/jellyfin/config/encoding.xml
      chmod 644 /var/lib/jellyfin/config/encoding.xml
      
      echo "Jellyfin NVENC configuration applied successfully"
    '';
  };
  
  # Ensure jellyfin user is in video group for GPU access
  users.users.jellyfin.extraGroups = [ "video" ];
}
