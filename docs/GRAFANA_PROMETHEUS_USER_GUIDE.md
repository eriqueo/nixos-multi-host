# Grafana & Prometheus User Guide for NixOS Homeserver

**Last Updated**: 2025-08-05  
**System**: NixOS Homeserver Monitoring Stack  
**Purpose**: Complete beginner's guide to using Grafana and Prometheus for monitoring your homeserver

---

## 🎯 **What Are Grafana & Prometheus?**

### **Prometheus** 📊 (The Data Collector)
- **What it does**: Collects metrics from your services every few seconds
- **Think of it as**: A librarian that goes around asking every service "How are you doing?" and writes down the answers
- **Examples**: CPU usage, memory usage, disk space, download speeds, service health

### **Grafana** 📈 (The Dashboard Creator)  
- **What it does**: Takes Prometheus data and creates beautiful charts and dashboards
- **Think of it as**: An artist that takes the librarian's notes and creates visual charts and graphs
- **Examples**: Line graphs of CPU over time, pie charts of disk usage, alerts when things go wrong

### **How They Work Together**
```
Your Services → Prometheus (collects data) → Grafana (makes pretty charts) → You (see what's happening)
```

---

## 🌐 **Accessing Your Monitoring**

### **Web Interface URLs**

#### **Reverse Proxy (Recommended - HTTPS)**
- **Grafana**: `https://hwc.ocelot-wahoo.ts.net/grafana/`
- **Prometheus**: `https://hwc.ocelot-wahoo.ts.net/prometheus/`

#### **Direct Port Access (Alternative)**
- **Grafana**: `http://192.168.1.13:3000` or `http://hwc.ocelot-wahoo.ts.net:3000`
- **Prometheus**: `http://192.168.1.13:9090` or `http://hwc.ocelot-wahoo.ts.net:9090`

### **Default Login (Grafana)**
- **Username**: `admin`
- **Password**: `admin123`
- **⚠️ Important**: Change this password after first login!

---

## 📊 **Understanding Your Current Setup**

### **What Metrics Are Being Collected**

Your system automatically collects data about:

#### **System Metrics** (Every 15 seconds)
```
CPU Usage:        How busy your processor is (0-100%)
Memory Usage:     How much RAM is being used  
Disk Space:       How full your drives are
Network Traffic:  How much data is flowing in/out
Temperature:      How hot your system is running
```

#### **Storage Metrics** (Every 30 seconds)
```
Hot Storage:      /mnt/hot usage (SSD)  
Cold Storage:     /mnt/media usage (HDD)
Processing Queue: Files waiting to be organized
Download Queue:   Active downloads in progress
Quarantine:       Files that had problems
```

#### **Service Health** (Every minute)
```
Sonarr:          TV show management - Up/Down
Radarr:          Movie management - Up/Down  
Lidarr:          Music management - Up/Down
qBittorrent:     Torrent client - Up/Down
SABnzbd:         Usenet client - Up/Down
Jellyfin:        Media server - Up/Down
```

#### **GPU Metrics** (Every 15 seconds)
```
GPU Usage:       How busy your NVIDIA card is
GPU Temperature: How hot your graphics card is
GPU Memory:      How much video memory is used
```

#### **Container Metrics** (Every 30 seconds)
```
Container CPU:   CPU usage per container
Container RAM:   Memory usage per container  
Container Status: Which containers are running
```

---

## 🖥️ **Using Grafana (The Visual Interface)**

### **First Login & Setup**

1. **Open Grafana**: `http://192.168.1.13:3000`
2. **Login**: admin / il0wwlm?
3. **Change Password**: Click on user icon → Profile → Change Password
4. **Explore Dashboards**: Left sidebar → Dashboards

### **Understanding the Interface**

#### **Left Sidebar Menu:**
- **🏠 Home**: Main dashboard list
- **📊 Dashboards**: All your monitoring dashboards  
- **🔍 Explore**: Query data directly (advanced)
- **🚨 Alerting**: Set up notifications
- **⚙️ Configuration**: Settings and data sources

#### **Dashboard Components:**
- **Panel**: Each chart/graph on a dashboard
- **Row**: Groups of related panels
- **Time Range**: Controls what time period you're viewing
- **Refresh**: How often the dashboard updates
- **Variables**: Filters to change what data is shown

### **Your Pre-Built Dashboards**

#### **System Overview Dashboard**
```
What you'll see:
- CPU usage over time (line graph)
- Memory usage percentage (gauge)  
- Disk usage by mount point (bar chart)
- Network activity (line graph)
- System uptime and load
```

**How to read it:**
- **Green = Good**: Normal operation
- **Yellow = Watch**: Getting busy but okay
- **Red = Problem**: Needs attention

#### **GPU Performance Dashboard**  
```
What you'll see:
- GPU utilization percentage (line graph)
- GPU temperature (line graph)
- GPU memory usage (gauge)
- Active GPU processes
```

**Normal values:**
- **Idle**: 0-10% usage, 30-50°C
- **Light Work**: 20-40% usage, 50-70°C  
- **Heavy Work**: 80-100% usage, 70-80°C
- **⚠️ Too Hot**: >85°C (should investigate)

#### **Media Pipeline Dashboard**
```
What you'll see:
- Service status (green/red indicators)
- Download queue sizes (number charts)
- Storage usage trends (line graphs)
- Processing queue activity
```

**What to watch for:**
- **Services going red**: Something is broken
- **Queues growing**: Downloads/processing backing up
- **Storage trends**: Running out of space

#### **Mobile Status Dashboard**
```
What you'll see:
- Simple, phone-friendly view
- Service up/down status
- Critical alerts only
- Response times
```

### **Navigating Dashboards**

#### **Time Controls (Top Right)**
- **Last 5m**: Very recent activity
- **Last 1h**: Good for troubleshooting
- **Last 24h**: Daily patterns
- **Last 7d**: Weekly trends
- **Custom**: Pick exact date/time range

#### **Zoom & Pan**
- **Zoom In**: Click and drag across a time period
- **Zoom Out**: Click the zoom out button
- **Pan**: Use left/right arrows

#### **Refresh Controls**
- **Manual**: Click refresh button
- **Auto**: Set to 5s, 30s, 1m, etc.
- **⚠️ Tip**: Don't use 5s refresh all the time (wastes resources)

---

## 🔍 **Using Prometheus (The Data Source)**

### **When to Use Prometheus Directly**
- **Grafana is easier** for most things
- **Use Prometheus when**:
  - Creating custom queries
  - Troubleshooting data collection
  - Learning what metrics are available

### **Accessing Prometheus**
1. **Open**: `http://192.168.1.13:9090`
2. **Main Page**: Shows service status and configuration
3. **Graph Tab**: Query and visualize data
4. **Targets Tab**: See what services are being monitored

### **Basic Prometheus Queries**

#### **System Metrics Examples**
```bash
# CPU usage percentage
100 - (avg(irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory usage percentage  
(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100

# Disk usage percentage
(node_filesystem_size_bytes - node_filesystem_free_bytes) / node_filesystem_size_bytes * 100

# Network traffic (bytes per second)
irate(node_network_receive_bytes_total[5m])
```

#### **Service Health Examples**
```bash
# Which services are up (1=up, 0=down)
up

# Specific service status
up{job="node-exporter"}
up{job="cadvisor"}  
up{job="blackbox-http"}

# Services that are down
up == 0
```

#### **Storage Examples**
```bash
# Hot storage usage
media_storage_usage_percentage{tier="hot"}

# Cold storage usage  
media_storage_usage_percentage{tier="cold"}

# Processing queue sizes
media_queue_files_total

# Files in quarantine
media_queue_files_total{queue="quarantine"}
```

#### **GPU Examples**
```bash
# GPU utilization
nvidia_gpu_utilization_percentage

# GPU temperature
nvidia_gpu_temperature_celsius

# GPU memory usage percentage
nvidia_gpu_memory_used_bytes / nvidia_gpu_memory_total_bytes * 100
```

### **Understanding Query Results**

#### **Instant Queries**
- **Shows**: Current value right now
- **Good for**: "What is my CPU usage right now?"

#### **Range Queries**  
- **Shows**: Values over time period
- **Good for**: "How has my CPU usage changed over the last hour?"

#### **Rate Functions**
- **irate()**: Instant rate (per second)
- **rate()**: Average rate over time
- **Good for**: Network traffic, disk I/O

---

## 🚨 **Setting Up Alerts**

### **What Should You Monitor?**

#### **Critical Alerts** (Fix Immediately)
```
System Down:           Any service stops responding
Disk Full:             Storage >95% full  
High Temperature:      CPU/GPU >85°C
Service Crashed:       *arr apps, download clients down
```

#### **Warning Alerts** (Check Soon)
```
High CPU:              CPU >80% for 10+ minutes
High Memory:           RAM >90% for 5+ minutes  
Storage Growing:       Disk >80% full
Download Issues:       Queues stuck for 30+ minutes
```

#### **Info Alerts** (Good to Know)
```
New Downloads:         When media starts downloading
Import Complete:       When new media is added
Backup Complete:       Daily backup success/failure
```

### **Creating Alerts in Grafana**

#### **Step 1: Create Alert Rule**
1. **Go to**: Alerting → Alert Rules → New Rule
2. **Choose Data Source**: Prometheus
3. **Write Query**: Example: `up{job="node-exporter"} == 0`
4. **Set Condition**: "IS BELOW 1" (for service down)
5. **Set Frequency**: How often to check (e.g., every 1m)

#### **Step 2: Set Alert Details**
```
Rule Name:     Node Exporter Down
Description:   System monitoring is not working
Severity:      Critical
For:          1m (wait 1 minute before alerting)
```

#### **Step 3: Create Notification**
1. **Go to**: Alerting → Contact Points → New Contact Point
2. **Choose Type**: 
   - **Email**: If you have email configured
   - **Webhook**: To send to Discord/Slack
   - **Custom**: Your own notification script

#### **Example Webhook for Discord**
```json
{
  "username": "Homeserver Monitor",
  "content": "🚨 ALERT: {{ .CommonLabels.alertname }}\n📝 {{ .CommonAnnotations.summary }}"
}
```

---

## 📱 **Mobile Access & Monitoring**

### **Phone-Friendly Dashboards**

Your system includes a **Mobile Status Dashboard** optimized for phones:

#### **Features**:
- **Large, clear status indicators**
- **Simple green/red service status**
- **Critical metrics only**
- **Fast loading on mobile data**

#### **Access**:
- **URL (HTTPS)**: `https://hwc.ocelot-wahoo.ts.net/grafana/`
- **URL (Direct)**: `http://hwc.ocelot-wahoo.ts.net:3000`
- **Dashboard**: Look for "Mobile Status" or "Mobile Service Status"

### **Grafana Mobile App**
1. **Download**: "Grafana" app from app store
2. **Add Server**: Enter your server URL
3. **Login**: Same credentials as web interface
4. **Sync**: Your dashboards will appear in the app

---

## 🛠️ **Troubleshooting Common Issues**

### **Dashboard Shows "No Data"**

#### **Check Data Source Connection**
1. **Go to**: Configuration → Data Sources → Prometheus
2. **Test Connection**: Should show "Data source is working"
3. **Check URL**: Should be `http://prometheus:9090` or `http://localhost:9090`

#### **Check Prometheus Targets**
1. **Open Prometheus**: `http://192.168.1.13:9090`
2. **Go to**: Status → Targets
3. **Look for RED entries**: These services aren't responding
4. **Common fixes**:
   - Restart the service: `sudo systemctl restart service-name`
   - Check container: `sudo podman ps | grep service-name`

### **Grafana Won't Load**

#### **Check Service Status**
```bash
# Check if Grafana container is running
sudo podman ps | grep grafana

# Check Grafana service logs
sudo journalctl -u podman-grafana.service

# Restart Grafana if needed
sudo systemctl restart podman-grafana.service
```

### **Missing GPU Metrics**

#### **Check GPU Exporter**
```bash
# Check if GPU exporter is running
sudo podman ps | grep nvidia-gpu-exporter

# Test GPU exporter directly
curl http://192.168.1.13:9445/metrics

# Check if GPU is accessible
nvidia-smi
```

### **Wrong Time Zone**

#### **Fix Dashboard Time**
1. **User Icon** → **Preferences**
2. **Timezone**: Select your timezone
3. **Save**: Dashboard times will update

---

## 📊 **Understanding Your Data**

### **What Good Metrics Look Like**

#### **System Health**
```
CPU Usage:        5-30% average, spikes to 80% ok
Memory Usage:     40-70% normal, >90% concerning
Disk Usage:       <80% good, >90% needs cleanup
Temperature:      <70°C good, >80°C concerning
```

#### **Storage Trends**
```
Hot Storage:      Should stay low (auto-migrated)
Cold Storage:     Gradual growth over time
Download Queue:   0-5 files normal, >20 stuck
Processing:       0-2 files normal, >10 backed up
```

#### **Service Health**
```
All Services:     Should be green/up 99%+ of time
Response Time:    <500ms good, >2s slow
Error Rate:       <1% good, >5% problems
```

### **Spotting Problems**

#### **Performance Issues**
- **Sawtooth patterns**: Services restarting repeatedly
- **Flat lines at 100%**: Resource exhaustion
- **Sudden drops to zero**: Service crashes

#### **Storage Issues**  
- **Steep upward trends**: Running out of space
- **Flat processing queues**: Migration not working
- **Growing quarantine**: File quality problems

#### **Network Issues**
- **High error rates**: Connection problems
- **Timeout spikes**: Network congestion
- **Zero traffic**: Service not communicating

---

## 🎯 **Daily Monitoring Routine**

### **Morning Check (2 minutes)**
1. **Open Grafana**: `http://hwc.ocelot-wahoo.ts.net:3000`
2. **System Overview**: Check for any red alerts
3. **Storage Status**: Verify hot/cold storage levels
4. **Service Health**: All services green?

### **Weekly Review (10 minutes)**
1. **Storage Trends**: Growing too fast?
2. **Performance Patterns**: Any degradation?
3. **Error Rates**: Increasing failures?
4. **Alert History**: What problems occurred?

### **Monthly Planning (30 minutes)**
1. **Capacity Planning**: When will storage fill up?
2. **Performance Trends**: Is system slowing down?
3. **Alert Tuning**: Too many/few notifications?
4. **Dashboard Updates**: Need new metrics?

---

## 📚 **Learning More**

### **Built-in Help**
- **Grafana**: Help → Documentation (in web interface)
- **Prometheus**: Documentation tab in web interface
- **Query Help**: Click "?" next to query boxes

### **Useful Keyboard Shortcuts**

#### **Grafana Shortcuts**
```
d + d = Go to dashboards
d + h = Go to home
d + p = Go to profile  
d + s = Go to search
? = Show all shortcuts
```

#### **Time Navigation**
```
t + z = Zoom out time range
t + ← = Move time range left  
t + → = Move time range right
```

### **Common Query Patterns**

#### **"Show me current value"**
```bash
metric_name
# Example: media_storage_usage_percentage{tier="hot"}
```

#### **"Show me change over time"**
```bash
rate(metric_name[5m])
# Example: rate(node_network_receive_bytes_total[5m])
```

#### **"Show me average over time"**
```bash
avg_over_time(metric_name[1h])
# Example: avg_over_time(node_cpu_usage[1h])
```

#### **"Show me only problems"**
```bash  
metric_name > threshold
# Example: media_storage_usage_percentage > 80
```

---

## 🔧 **Customization Ideas**

### **Custom Dashboards You Might Want**

#### **Personal Media Dashboard**
- **Recent Downloads**: What media was added today?
- **Library Growth**: How fast is your collection growing?
- **Quality Distribution**: How much 4K vs 1080p content?
- **Watch History**: Most accessed content (if tracking enabled)

#### **Efficiency Dashboard**
- **Download Speeds**: How fast are downloads completing?
- **Processing Times**: How long does import take?
- **Storage Efficiency**: Compression ratios by media type
- **Error Rates**: Download failures by indexer/tracker

#### **Security Dashboard**
- **VPN Status**: Is VPN always connected?
- **Failed Logins**: Any unauthorized access attempts? 
- **Network Traffic**: Unusual bandwidth patterns?
- **Service Exposure**: What ports are open to internet?

### **Custom Alerts You Might Want**

#### **Smart Home Integration**
- **Phone Notifications**: When downloads complete
- **LED Indicators**: Change room lights when system has problems
- **Voice Alerts**: "Your Plex server is down" via smart speaker

#### **Automation Triggers**
- **Auto-cleanup**: Trigger cleanup when storage >85%
- **Download Throttling**: Slow downloads during work hours
- **Backup Triggers**: Start backup when new media imported

---

## 🎉 **Quick Win: Your First Custom Dashboard**

### **Create a "My Homeserver" Dashboard**

1. **New Dashboard**: Dashboards → New → New Dashboard
2. **Add Panel**: Click "+ Add visualization"
3. **Choose Prometheus**: Select your data source
4. **Add Query**: `media_storage_usage_percentage{tier="hot"}`
5. **Panel Title**: "Hot Storage Usage"
6. **Visualization**: Stat (big number display)
7. **Units**: Percent (0-100)
8. **Thresholds**: Green <70, Yellow 70-85, Red >85
9. **Save**: Give dashboard a name like "My Homeserver"

**Repeat for:**
- Cold storage usage
- Service count (how many services up)
- Current downloads
- CPU usage

**Result**: Your personal "at-a-glance" dashboard showing the most important numbers!

---

## 🎯 **Key Takeaways**

### **Grafana = Pretty Pictures**
- **Use daily** for quick health checks
- **Use weekly** for trend analysis  
- **Use monthly** for capacity planning
- **Mobile friendly** for checking while away

### **Prometheus = Raw Data**
- **Use rarely** for custom queries
- **Use when** Grafana doesn't have what you need
- **Use for** understanding what data is available

### **Monitoring Philosophy**
1. **Start Simple**: Use pre-built dashboards first
2. **Add Gradually**: Create custom views as you learn
3. **Alert Thoughtfully**: Too many alerts = ignored alerts
4. **Review Regularly**: Monitoring is only useful if you look at it

Your homeserver generates tons of useful data - Grafana and Prometheus help you turn that data into actionable insights! 📊✨