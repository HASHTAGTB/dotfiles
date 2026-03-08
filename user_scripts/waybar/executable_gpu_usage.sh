#!/bin/bash

# Check for NVIDIA
if command -v nvidia-smi &> /dev/null; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{print $1}')
    temp=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader | awk '{print $1}')
    tooltip="GPU Usage: ${usage}%\nTemp: ${temp}°C\n\nLMB: nvtop"
# Check for AMD
elif [ -f "/sys/class/drm/card0/device/gpu_busy_percent" ]; then
    usage=$(cat /sys/class/drm/card0/device/gpu_busy_percent)
    tooltip="GPU Usage: ${usage}%\n\nLMB: nvtop"
else
    usage=0
    tooltip="No supported GPU detected"
fi

# Define state classes to trigger CSS warnings (matching your CPU module thresholds)
class="normal"
if [ "$usage" -ge 80 ]; then
    class="critical"
elif [ "$usage" -ge 60 ]; then
    class="warning"
fi

# Output JSON for Waybar
echo '{"text": "'"${usage}"'", "tooltip": "'"${tooltip}"'", "class": "'"${class}"'"}'
