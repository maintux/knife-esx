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

