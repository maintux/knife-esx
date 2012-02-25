# Sat Feb 25 12:16:01 CET 2012 - 0.1.5 

* Patch from @pperezrubio adding multiple networks support

    knife esx vm create --vm-disk ubuntu-oneiric.vmdk \
                        --vm-name testvm --datastore datastore1 \
                        --esx-host 192.168.88.1 --ssh-user ubuntu \
                        --ssh-password ubuntu \
                        --vm-network "VLAN-Integration,VLAN-Test"


This will create a VM with two NICs, attaching them to the VLAN-Integration and VLAN-Test networks respectively.


