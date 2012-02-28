# 0.2 - 2012/02/28

* **Added --batch and --async options**

Inspired by spiceweasel from Matt Ray (https://github.com/mattray/spiceweasel), I've added a batch mode where a YAML file describes the VMs you want to bootstrap and where (you can deploy to multiple hypervisors).
    
    knife esx vm create --batch batch.yml 

Sample batch.yml file:

    ---
    :test1:
      'extra-args': --no-host-key-verify
      'vm-memory': 128
      'esx-host': esx-server-1 
      'esx-password': secret 
      'ssh-user': ubuntu
      'ssh-password': ubuntu
      'vm-disk': /home/rubiojr/mnt/mirror/virtual_appliances/ubuntu1110-x64-vmware-tools.vmdk
      'datastore': datastore2
    :test2:
      'extra-args': --no-host-key-verify 
      'vm-memory': 128
      'esx-host': esx-server-1 
      'esx-password': secret
      'ssh-user': ubuntu
      'ssh-password': ubuntu
      'vm-disk': /home/rubiojr/mnt/mirror/virtual_appliances/ubuntu1110-x64-vmware-tools.vmdk
      'datastore': datastore2
    :test3:
      'extra-args': --no-host-key-verify 
      'vm-memory': 256
      'esx-host': esx-server-1 
      'esx-password': secret
      'ssh-user': ubuntu
      'ssh-password': ubuntu
      'vm-disk': /home/rubiojr/mnt/mirror/virtual_appliances/ubuntu1110-x64-vmware-tools.vmdk
      'datastore': datastore2

This will try to create three VMs (testvm1, testvm2 and testvm3) sequentially. VM definitions inside the batch file accept all the parameters that can be used with knife-esx.

If you want to bootstrap the VMs asynchronously, use the --async flag.

    knife esx vm create --batch batch.yml --async

Standard output and error log is redirected to /tmp/knife_esx_vm_create_VMNAME.log, so if we use the deploy script from above, three log files will be created:

    /tmp/knife_esx_vm_create_test1.log
    /tmp/knife_esx_vm_create_test2.log
    /tmp/knife_esx_vm_create_test3.log

* **Added --skip-bootstrap flag**

If the flag is used the VM will be created but 
  the bootstrap template/script won't be executed (it also means that Chef won't be installed).

* **Fixed bug preventing knife-esx to create a VM when the hypervisor has an empty root password.**

**KNOWN ISSUES**

* To use --batch without --skip-bootstrap, the ssh user (--ssh-user) needs to be able to sudo without asking for a password (i.e. adding something like 'ubuntu ALL=(ALL) NOPASSWD: ALL' to /etc/sudoers in the appliance template) otherwise the bootstraping process won't work if more than one VM is being deployed. 

# 0.1.5 - 2012/02/25

* Patch from @pperezrubio adding multiple networks support

    knife esx vm create --vm-disk ubuntu-oneiric.vmdk \
                        --vm-name testvm --datastore datastore1 \
                        --esx-host 192.168.88.1 --ssh-user ubuntu \
                        --ssh-password ubuntu \
                        --vm-network "VLAN-Integration,VLAN-Test"

This will create a VM with two NICs, attaching them to the VLAN-Integration and VLAN-Test networks respectively.

Fixed MAC addresses can also be assigned to each NIC using the --mac-address parameter:
    
    knife esx vm create --vm-disk ubuntu-oneiric.vmdk \
                        --vm-name testvm --datastore datastore1 \
                        --esx-host 192.168.88.1 --ssh-user ubuntu \
                        --ssh-password ubuntu \
                        --vm-network "VLAN-Integration,VLAN-Test" \
                        --mac-address "00:01:02:03:04:05,00:01:02:03:04:06"

MAC address 00:01:02:03:04:05 will be assigned to VLAN-Integration NIC and 00:01:02:03:04:06 to the VLAN-Test NIC.

If a MAC address is omitted it will be dynamically generated:
    
knife esx vm create --vm-disk ubuntu-oneiric.vmdk \
                        --vm-name testvm --datastore datastore1 \
                        --esx-host 192.168.88.1 --ssh-user ubuntu \
                        --ssh-password ubuntu \
                        --vm-network "VLAN-Integration,VLAN-Test" \
                        --mac-address ",00:01:02:03:04:06"

Note that I did not specify the first MAC address, so VLAN-Integration NIC will get a random MAC.

