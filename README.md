# check-_resources_for_proxmoxserver
Bash script uses to check recources for proxmoxservers

This script show many details about server that used in proxmox to create vps on it.

##### The expected details are:-

################# Server Name #################

Server Name: *************
<---------------------------------------------------------------------->

################# CPU #################

Number of actual server CPUs: *****
Number of CPUs allocated for VMs: *****
Server's free CPU: ******
<---------------------------------------------------------------------->

################# Ram #################

Server's Actual Memory: ******
Allocated Memory for VMs: *****
Server's Free Memory: *****
<---------------------------------------------------------------------->

################# Disks #################

Storage name: *****
Storage type: ******
Total disk size: *****
Used by VPSs: ******
Free space available to use: 

# Running
To Install run this script it is so easy just clone the repo and enter into the directory then:
```
$ ./proxmox_check_resource.sh
```
