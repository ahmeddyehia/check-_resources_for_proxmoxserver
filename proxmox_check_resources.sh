#!/bin/bash

# Function to print a line
function print_line(){
    echo "<---------------------------------------------------------------------->"
}

# Function to determine disk type 
disk_type() {
 local disk_name="$1"
  local base_disk

  if [ "$disk_name" == "local-lvm" ]; then
    base_disk=$(lsblk -f | grep "LVM2_member" | cut -f 1 -d " " | tr -d "└─" | sed 's/[0-9]//g')
  else
    base_disk=$(lsblk -f | grep -w "$disk_name" | cut -f 1 -d " " | sed 's/[0-9]//g' | tr -d "└─")
  fi

  if [ -n "$base_disk" ]; then
    rotational=$(cat "/sys/block/$base_disk/queue/rotational" 2>/dev/null)
    case "$rotational" in
      0) echo "SSD" ;;
      1) echo "HDD" ;;
      *) echo "Unknown" ;;
    esac
  else
    echo "Couldn't find information about it"
  fi
}
############################################# Server Name ##############################################################
# Print server name
echo "
################# Server Name #################
"
echo "Server Name: $(hostname)"
print_line
############################################# CPU ##############################################################
echo "
################# CPU #################
"
# Print server CPU details
actual_cpu=$(nproc)
echo "Number of actual server CPUs: ${actual_cpu}"

vm_id=$(qm list | awk 'NR>1{print $1}')
vm_cpu_usage=0

for vm in ${vm_id}; do
    used_cores=$(qm config ${vm} | grep cores | awk '{print $2}')
    vm_cpu_usage=$((${vm_cpu_usage} + ${used_cores} * 2))
done

free_cpu=$(($actual_cpu - $vm_cpu_usage))
echo "Number of CPUs allocated for VMs: ${vm_cpu_usage}"
echo "Server's free CPU: ${free_cpu}"
print_line

############################################# MEMORY ##############################################################
echo "
################# Ram #################
"
# Print server RAM details
vm_mem=$(qm list | awk 'NR>1{print $4}')
allocated_mem=0

for mem in ${vm_mem}; do
    allocated_mem=$((${allocated_mem} + ${mem} / 1024)) # Convert to GB
done

actual_mem=$(free -g | grep Mem: | awk '{print $2}')
free_mem=$(($actual_mem - $allocated_mem))

echo "Server's Actual Memory: ${actual_mem}G"
echo "Allocated Memory for VMs: ${allocated_mem}G"
echo "Server's Free Memory: ${free_mem}G"
print_line

################################################################## DISKS #########################################
# Print server Disks details
declare -A disk_usage  
declare -A total_disk_size
disks=$(pvesm status | awk '/active/{print $1}')
 
# Get total disk size for each disk in GB
for disk in $disks; do
  total_size=$(pvesm status | awk -v disk="$disk" '$1 == disk && /active/ {print $4}')

      total_size_gb=$(echo "scale=2; $total_size / 1048576" | bc)  # Convert to GB
      total_disk_size[$disk]=$total_size_gb

done

# Calculate disk usage 
while read -r vmid; do
  vm_config=$(qm config "$vmid")

  for disk in $disks; do
    if echo "$vm_config" | grep -q "$disk:"; then
      # Extract disk sizes
      disk_sizes=$(echo "$vm_config" | grep "$disk:" | awk -F'size=' '{print $2}' | tr -d ' ')

      for size in $disk_sizes; do
        case "${size: -1}" in
          G) size_gb=${size%G} ;;  # Keep size in GB
          T) size_gb=$(echo "scale=2; ${size%T} * 1024" | bc) ;;  # Convert TB to GB
          K) size_gb=$(echo "scale=2; ${size%K} / 1048576" | bc) ;;  # Convert K to GB
          *) continue ;;
        esac
        disk_usage[$disk]=$(echo "scale=2; ${disk_usage[$disk]:-0} + $size_gb" | bc)
      done
    fi
  done
done <<< "$vm_id"


# Print the total usage and remaining space for each disk
echo "
################# Disks #################
"

for disk in "${!total_disk_size[@]}"; do
  total=${total_disk_size[$disk]:-0}  
  used=$(echo "scale=2; ${disk_usage[$disk]:-0} * 1.074" | bc)  
  free=$(echo "scale=2; $total - $used" | bc)  
  storage_type=$(disk_type "$disk")

  echo "Storage name: $disk"
  echo "Storage type: $storage_type"
  echo "Total disk size: $total GB"
  echo "Used by VPSs: $used GB"
  printf "Free space available to use: %.2f GB\n" "$free"  
  echo
  print_line
done