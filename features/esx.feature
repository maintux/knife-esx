Feature: knife esx
  
  Scenario: Run esx create vm without arguments
    When I run `knife esx vm create`
    Then the output should contain:
      """
      ERROR: You have not provided a valid VMDK file. (--vm-disk)
      """
  Scenario: Print help
    When I run `knife esx --help`
    Then the output should contain "Available esx subcommands:"

  Scenario: Unknown esx create sub-command
    When I run `knife esx create foobar`
    Then the output should contain "FATAL: Cannot find sub command for:"
  
  Scenario: Invalid VMDK file
    When I run `knife esx vm create --vm-disk /tmp/foo9098jfj`
    Then the output should contain "Invalid VMDK disk file (--vm-disk)"
  
  Scenario: Missing VM name
    When I run `knife esx vm create --vm-disk /tmp/test.vmdk`
    Then the output should contain "ERROR: Invalid Virtual Machine name (--vm-name)"
  
  Scenario: Missing Host option
    When I run `knife esx vm create --vm-disk /tmp/test.vmdk --vm-name knife-esx-test`
    Then the output should contain "ERROR: RuntimeError: host option required"
  
  Scenario: Invalid ESX host
    When I run `knife esx vm create --vm-disk /tmp/m0n0wall-stream.vmdk --vm-name knife-esx-test --esx-host localhost --esx-password temporal --datastore datastore1`
    Then the output should contain "ERROR: Network Error: Connection refused"
  
  Scenario: Invalid ESX password
    When I run `knife esx vm create --vm-disk /tmp/m0n0wall-stream.vmdk --vm-name knife-esx-test --esx-host esx-test-host --esx-password oiusdf`
    Then the output should contain "ERROR: RbVmomi::Fault: InvalidLogin: Cannot complete login due to an incorrect user name or password"
  
  Scenario: Unknown host
    When I run `knife esx vm create --vm-disk /tmp/m0n0wall-stream.vmdk --vm-name knife-esx-test --esx-host lllocalhost --esx-password temporal --datastore datastore1`
    Then the output should contain "ERROR: Network Error: getaddrinfo: Name or service not known"
  
  Scenario: Missing VMWare Tools in server
    When I run `knife esx vm create --vm-disk /tmp/m0n0wall-stream.vmdk --vm-name knife-esx-test --esx-host esx-test-host --esx-password temporal --datastore datastore1`
    Then the output should contain "Timeout trying to reach the VM. Does it have vmware-tools installed?"
  
  Scenario: Existing VM disk in host
    When I run `knife esx vm create --vm-disk /tmp/m0n0wall-stream.vmdk --vm-name knife-esx-test --esx-host esx-test-host --esx-password temporal --datastore datastore1`
    Then the output should contain "ERROR: Exception: Destination file"
  
  Scenario: Delete Existing VM 
    When I run `knife esx vm delete --force-delete yes knife-esx-test --esx-host esx-test-host --esx-password temporal`
    Then the output should contain "WARNING: Deleted virtual machine knife-esx-test"

  Scenario: Delete non-existent VM 
    When I run `knife esx vm delete --force-delete yes knife-esx-test --esx-host esx-test-host --esx-password temporal`
    Then the output should contain "WARNING: Virtual Machine knife-esx-test not found"

  @announce
  Scenario:  Success bootstraping VM
    When I run `knife esx vm create --template-file /home/rubiojr/.chef/bootstrap/ubuntu11.10-gems.erb --vm-disk /home/rubiojr/tmp/ubuntu1110-x64-vmware-tools.vmdk --vm-name knife-esx-test-ubuntu --esx-host esx-test-host --esx-password temporal --datastore datastore1 --ssh-user ubuntu --ssh-password ubuntu --no-host-key-verify`
    Then the output should contain "Done!"

  Scenario: List virtual machine
    When I run `knife esx vm list --esx-host esx-test-host --esx-password temporal`
    Then the output should contain "knife-esx-test-ubuntu"

  Scenario: Delete Existing VM 
    When I run `knife esx vm delete --force-delete yes knife-esx-test-ubuntu --esx-host esx-test-host --esx-password temporal`
    Then the output should contain "WARNING: Deleted virtual machine knife-esx-test-ubuntu"
