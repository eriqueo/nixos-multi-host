# SketchUp VM Setup Guide

**Last Updated:** August 2, 2025  
**System:** heartwood-laptop (NixOS 25.11)  
**Purpose:** Step-by-step guide for creating and configuring a Windows VM for SketchUp

---

## 🚀 Starting virt-manager

### Option 1: From Terminal
```bash
virt-manager
```

### Option 2: From Desktop (GUI)
- Open application launcher and search for "Virtual Machine Manager"
- Or use the desktop shortcut if available

---

## 🔧 Creating Your SketchUp VM

### Step 1: Create New VM
1. Click **"Create a new virtual machine"** (big + icon)
2. Select **"Local install media (ISO image or CDROM)"**
3. Click **Forward**

### Step 2: Choose Installation Media
1. **Browse** to select your Windows ISO file
   - Location: `/opt/sketchup/vm/iso/` (recommended)
   - Supported: Windows 10 LTSC, Windows 10, or Windows 11
2. **Operating system**: Select "Microsoft Windows 10" (or 11)
3. Click **Forward**

### Step 3: Memory and CPU Configuration
**Recommended Settings:**
- **Memory (RAM)**: **12288 MB** (12GB) - **16384 MB** (16GB) for better performance
- **CPUs**: **8** cores (out of your 22 available)
- Click **Forward**

### Step 4: Storage Configuration
1. **Create a disk image for the virtual machine**
2. **Size**: **80 GB** minimum (100GB recommended)
3. **Browse** and navigate to `/opt/sketchup/vm/images/`
4. **Name**: `sketchup-windows.qcow2`
5. Click **Forward**

### Step 5: Final VM Configuration
1. **Name**: `sketchup-windows` (important - matches our scripts)
2. **✅ Check "Customize configuration before install"**
3. Click **Finish**

---

## ⚙️ VM Optimization (Critical for SketchUp Performance)

### Overview Tab
- **Chipset**: **Q35** (modern chipset)
- **Firmware**: **UEFI x86_64** (if available, required for modern Windows)

### CPUs Tab
- **Topology**: 
  - **Sockets**: 1
  - **Cores**: 8 (or your allocated amount)
  - **Threads**: 1
- **Model**: Host passthrough (for best performance)

### Memory Tab
- **Current allocation**: Confirm 12-16GB
- **Enable shared memory**: ✅ Checked

### Boot Options Tab
- **Enable boot menu**: ✅ Checked
- **Boot device order**: 
  1. CDROM (for installation)
  2. Hard Disk

### SATA Disk Tab (Performance Critical)
- **Advanced options**:
  - **Cache mode**: **writeback** (best performance)
  - **IO mode**: **threads**
- **Storage format**: qcow2

### Graphics Tab
- **Type**: QXL (start with this, upgrade to GPU passthrough later if needed)
- **Listen type**: Address
- **3D acceleration**: ✅ Enabled

### Network Tab
- **Network source**: NAT (default)
- **Device model**: virtio (better performance)

### Add Hardware (Click "Add Hardware" button)

#### Required: Shared Folder
1. Click **"Add Hardware"**
2. Select **"Filesystem"**
3. Configure:
   - **Type**: mount
   - **Mode**: mapped
   - **Source path**: `/opt/sketchup/vm/shared`
   - **Target path**: `sketchup-shared`
4. Click **Finish**

#### Optional: Sound
1. **Add Hardware** > **Sound**
2. **Model**: ich9 (modern sound)

### Apply Configuration
1. Click **Apply** to save all settings
2. Click **Begin Installation**

---

## 💿 Windows Installation Process

### Boot and Install
1. **Boot from ISO** - Windows installer should start automatically
2. **Language and Region**: Select your preferences
3. **Install Type**: Custom (advanced)
4. **Drive Selection**: Select the virtual disk (should be ~80GB)
5. **Install Windows**: Follow standard installation prompts

### Initial Windows Setup
1. **User Account**: Create local account (avoid Microsoft account for VMs)
2. **Privacy Settings**: Disable telemetry and data collection
3. **Windows Updates**: Let initial updates install

### Install VirtIO Drivers (Critical for Performance)
1. **Download virtio-win ISO**:
   ```bash
   # From host system
   cd /opt/sketchup/vm/iso/
   wget https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso
   ```
2. **Mount VirtIO ISO** in VM (Devices > CD/DVD > virtio-win.iso)
3. **Install drivers**:
   - Device Manager > Unknown devices > Update drivers
   - Browse to mounted CD drive
   - Install all VirtIO drivers (network, storage, memory balloon)

### Windows Optimization for VM
1. **Disable Windows Search indexing**
2. **Disable Windows Defender** (optional, but improves performance)
3. **Set Power Plan** to High Performance
4. **Disable visual effects**:
   - System Properties > Advanced > Performance > Adjust for best performance

---

## 🎨 SketchUp Installation

### Prepare Installation Files
```bash
# From host system - copy installer to shared folder
cp /opt/sketchup/installer/SketchUpFull-2025-0-571-242.exe /opt/sketchup/vm/shared/
```

### Install SketchUp in Windows VM
1. **Access shared folder** in Windows:
   - Open File Explorer
   - Look for network drive or mounted folder
   - Navigate to `sketchup-shared`
2. **Run installer**: `SketchUpFull-2025-0-571-242.exe`
3. **Follow installation prompts**
4. **License**: Enter your SketchUp license key
5. **Test installation**: Open SketchUp and create a simple model

### Configure SketchUp for VM
1. **Graphics settings**:
   - Go to Window > Preferences > OpenGL
   - Ensure hardware acceleration is enabled
   - Adjust anti-aliasing as needed
2. **Auto-save settings**:
   - File > Preferences > General
   - Enable auto-save every 5-10 minutes
3. **Backup location**: Point to shared folder for easy host access

---

## 🔧 VM Management Commands

### Using the SketchUp VM Script
```bash
# Check VM status
~/.local/bin/sketchup-vm status

# Start VM and open viewer
~/.local/bin/sketchup-vm start

# Connect to running VM
~/.local/bin/sketchup-vm connect

# Stop VM gracefully
~/.local/bin/sketchup-vm stop

# Force stop if VM is stuck
~/.local/bin/sketchup-vm force-stop

# Show VM information
~/.local/bin/sketchup-vm info

# Open shared folder
~/.local/bin/sketchup-vm shared

# Backup VM configuration
~/.local/bin/sketchup-vm backup
```

### Direct virsh Commands
```bash
# List all VMs
virsh list --all

# Start VM
virsh start sketchup-windows

# Stop VM gracefully
virsh shutdown sketchup-windows

# Force stop VM
virsh destroy sketchup-windows

# VM information
virsh dominfo sketchup-windows

# Edit VM configuration
virsh edit sketchup-windows
```

---

## 🔗 File Sharing Between Host and VM

### Host to VM (Project Files)
```bash
# Copy current projects to VM
cp ~/06-projects/cad/sketchup-current/*.skp /opt/sketchup/vm/shared/

# Copy SketchUp resources
cp -r /opt/sketchup/resources/* /opt/sketchup/vm/shared/
```

### VM to Host (Backup Projects)
- Save SketchUp files to the shared folder from within Windows
- Access from host at `/opt/sketchup/vm/shared/`
- Move completed projects to archive:
```bash
mv /opt/sketchup/vm/shared/*.skp /opt/sketchup/projects/archive/
```

---

## 🚨 Troubleshooting

### VM Won't Start
```bash
# Check libvirtd status
systemctl status libvirtd

# Check user permissions
groups eric | grep libvirtd

# Check VM configuration
virsh dumpxml sketchup-windows

# Check QEMU logs
journalctl -u libvirtd --no-pager -n 50
```

### Poor SketchUp Performance
1. **Increase VM resources**:
   - More RAM (up to 16GB)
   - More CPU cores (up to 12)
2. **Check graphics**:
   - Ensure hardware acceleration is enabled in SketchUp
   - Consider GPU passthrough for professional work
3. **Storage optimization**:
   - Use writeback cache mode
   - Ensure host SSD has enough free space

### SketchUp OpenGL Errors
1. **Update graphics drivers** in Windows VM
2. **Try different graphics settings** in SketchUp:
   - Window > Preferences > OpenGL
   - Try software rendering if hardware fails
3. **Consider GPU passthrough** for native graphics performance

### Shared Folder Not Working
```bash
# Check mount points in VM (Windows)
# Look for network drives in File Explorer

# Verify host folder permissions
ls -la /opt/sketchup/vm/shared/

# Restart VM to refresh shared folders
~/.local/bin/sketchup-vm stop
~/.local/bin/sketchup-vm start
```

### Network Issues in VM
1. **Check VirtIO network drivers** are installed
2. **VM network settings**: Should be NAT or bridged
3. **Windows firewall**: May need to allow virt-manager

---

## 🎯 Performance Optimization Tips

### Host System
```bash
# Monitor host resources during VM use
htop

# Check SSD health (important for VM performance)
sudo smartctl -a /dev/nvme0n1

# Monitor VM resource usage
virsh domstats sketchup-windows
```

### VM Tuning
1. **CPU pinning** for dedicated cores
2. **Huge pages** for memory optimization
3. **GPU passthrough** for professional 3D work
4. **NVMe passthrough** for maximum storage performance

### SketchUp Optimization
1. **Model complexity**: Keep models under 100MB for smooth performance
2. **Component usage**: Use components instead of groups for repeated elements
3. **Texture optimization**: Compress large texture files
4. **Purge unused**: Regularly purge unused components and materials

---

## 📚 Advanced Configuration

### GPU Passthrough Setup
- See `/etc/nixos/docs/SKETCHUP-VM.md` for GPU passthrough configuration
- Requires Intel Arc GPU passthrough setup
- Provides near-native graphics performance

### Multiple VM Configurations
- Create different VMs for different SketchUp versions
- Snapshot VMs for quick restoration
- Template VMs for rapid deployment

### Automation
```bash
# Automated backup script
~/.local/bin/sketchup-vm backup

# Scheduled VM snapshots
virsh snapshot-create-as sketchup-windows "snapshot-$(date +%Y%m%d)"
```

---

## 📁 File Locations Reference

- **VM Images**: `/opt/sketchup/vm/images/`
- **ISO Files**: `/opt/sketchup/vm/iso/`
- **Shared Folder**: `/opt/sketchup/vm/shared/`
- **VM Configs**: `/opt/sketchup/vm/config/`
- **User Projects**: `~/06-projects/cad/sketchup-current/`
- **SketchUp Installers**: `/opt/sketchup/installer/`

---

**Success Indicator**: SketchUp should run smoothly with hardware-accelerated OpenGL, and you should be able to save/load files through the shared folder system.