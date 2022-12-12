```
# PodOOMKilling
sudo sh -c "echo 'kernel: BUG: Task in kubepods killed as a result of limit .' >> /dev/kmsg"

# TaskHung
sudo sh -c "echo 'kernel: INFO: task java:xxx blocked for more than 120 seconds.' >> /dev/kmsg"

# UnregisterNetDevice
sudo sh -c "echo 'kernel: BUG: unregister_netdevice: waiting for veth31bce17 to become free. Usage count = 1' >> /dev/kmsg"

# KernelOops
sudo sh -c "echo 'kernel: BUG: unable to handle kernel NULL pointer dereference at TESTING' >> /dev/kmsg"



# CPUSoftLockup
sudo sh -c "echo 'kernel: BUG: soft lockup' >> /dev/kmsg"

# CPUHardLockup
sudo sh -c "echo 'kernel: BUG: NMI watchdog: Watchdog detected hard LOCKUP' >> /dev/kmsg"



# FilesystemIsReadOnly
sudo sh -c "echo 'kernel: BUG: Remounting filesystem read-only' >> /dev/kmsg"

# CPUTemperatureHigh
sudo sh -c "echo 'kernel: BUG: temperature above threshold' >> /dev/kmsg"



# AUFSUmountHung
sudo sh -c "echo 'kernel: INFO: task umount:11451 blocked for more than 300 seconds.' >> /dev/kmsg"

# DockerHung
sudo sh -c "echo 'kernel: INFO: task docker:20744 blocked for more than 120 seconds.' >> /dev/kmsg"

# NvmeError
sudo sh -c "echo 'kernel: BUG: nvme Timeout I/O' >> /dev/kmsg"
```