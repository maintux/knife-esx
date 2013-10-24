# Knife ESX

## DESCRIPTION:

This is the unofficial Opscode Knife plugin for ESX. This plugin gives knife the ability to create, bootstrap, and manage virtual machines in a VMWare ESX/ESXi host.

You'll need an ESX(i)4/5 host with SSH enabled and a privileged user account to connect to it via SSH.

You'll also need a base VM template (a VMDK in fact) with CentOS/Ubuntu/Fedora and vmware-tools installed.

If you're using VMWare ESXi with a free license, don't forget the <tt>--free-license</tt> option or you'll get the following error:

    ERROR: RbVmomi::Fault: RestrictedVersion: Current license or ESXi version prohibits execution of the requested operation

Home page: http://github.com/maintux/knife-esx

## INSTALLATION:

Be sure you are running the latest version Chef. Versions earlier than 0.10.0 don't support plugins:

    gem install chef

This plugin is distributed as a Ruby Gem. To install it, run:

    gem install knife-esx

Depending on your system's configuration, you may need to run this command with root privileges.

## CONFIGURATION:

In order to communicate with the ESX Cloud API you will have to tell Knife about your Username and API Key.  The easiest way to accomplish this is to create some entries in your <tt>knife.rb</tt> file:

    knife[:esx_host] = "Your ESX host address"
    knife[:esx_username]  = "root"
    knife[:esx_password]  = "secret"

You also have the option of passing your ESX Host/Username/Password into the individual knife subcommands using the <tt>--esx-host</tt> <tt>--esx-username</tt> and <tt>--esx-password</tt> command options

## COMMAND LINE BASIC OPTIONS

<pre>
--esx-host HOST                           The ESX host to connect to (default: 127.0.0.1)
--esx-username USERNAME                   The ESX username used to connect to the host (default: root)
--esx-password PASSWORD                   The ESX user password
--esx-templates-dir TEMPLATES_DIRECTORY   The folder where the VM template is stored
--free-license                            If the ESX(i) host has a free license (default: false)
--insecure                                Use an insecure connection (default: true)
</pre>

For subcommand specific options, refer to the related subcommand

## SUBCOMMANDS:

This plugin provides the following Knife subcommands.  Specific command options can be found by invoking the subcommand with a `--help` flag

### knife esx vm create

Provisions a new virtual machine in the ESX host and then perform a Chef bootstrap (using the SSH protocol).  The goal of the bootstrap is to get Chef installed on the target system so it can run Chef Client with a Chef Server. The main assumption is a baseline OS installation exists (provided by the provisioning). It is primarily intended for Chef Client systems that talk to a Chef server.  By default the virtual machine is bootstrapped using the {ubuntu10.04-gems}[https://github.com/opscode/chef/blob/master/chef/lib/chef/knife/bootstrap/ubuntu10.04-gems.erb] template.  This can be overridden using the <tt>-d</tt> or <tt>--template-file</tt> command options.

#### _Command line options_

<pre>
--vm-disk FILE                                            The path to the VMDK disk file
--vm-name NAME                                            The Virtual Machine name
--vm-cpus CPUS                                            The Virtual Machine total number of virtual cpus (for the calculation see below) (default: 1)
--vm-cpu-cores CPU_CORES                                  The number of cores per CPU socket. The number of sockets is calculated as <CPUS>=<SOCKETS>*<CPU_CORES> (default: 1)
--datastore NAME                                          The Datastore to use for the VM files (default: datastore1)
--guest-id NAME                                           The VM GuestID (default: otherGuest)
--vm-memory MEM                                           The VM memory in MB (default: 512)
-N NAME | --node-name NAME                                The Chef node name for your new node
--prerelease                                              Install the pre-release chef gems
--bootstrap-version VERSION                               The version of Chef to install
-d DISTRO | --distro DISTRO                               Bootstrap a distro using a template (default: ubuntu10.04-gems)
--template-file TEMPLATE                                  Full path to location of template to use
--use-template NAME                                       Try to use an existing template instead of importing disk
-r RUN_LIST | --run-list RUN_LIST                         Comma separated list of roles/recipes to apply
-j JSON_ATTRIBUTES | --json-attributes JSON_ATTRIBUTES    A JSON string to be added to the first run of chef-client
-x USERNAME | --ssh-user USERNAME                         The ssh username (default: root)
-P PASSWORD | --ssh-password PASSWORD                     The ssh password
-G GATEWAY | --ssh-gateway GATEWAY                        The ssh password
-i IDENTITY_FILE | --identity-file IDENTITY_FILE          The SSH identity file used for authentication
--no-host-key-verify                                      Disable host key verification
--vm-network network[,network..]                          Network where nic is attached to (default: 'VM Network')
-M mac[,mac..] | --mac-address mac[,mac..]                Mac address list
--skip-bootstrap                                          Skip bootstrap process (Deploy only mode)
--async                                                   Deploy the VMs asynchronously (Ignored unless combined with --batch)
--batch script.yml                                        Use a batch file to deploy multiple VMs
</pre>

### knife esx vm delete

Deletes an existing virtual machine in the currently configured ESX host by the virtual machine name. You can find the instance id by entering 'knife esx vm list'. Please note - this does not delete the associated node and client objects from the Chef server.

#### _Command line options_

    --force-delete YES|NO     Don't confirm the deletion if yes (default: no)

### knife esx vm list

Outputs a list of all virtual machines in the currently configured ESX host.  Please note - this shows all the virtual machines available in the ESX host, some of which may not be currently managed by the Chef server.

### knife esx template list

Outputs a list of all templates in the currently configured ESX host.

### knife esx template delete TEMPLATE_NAME [TEMPLATE_NAME] (options)

Deletes a template

#### _Command line options_

    --force-delete YES|NO     Don't confirm the deletion if yes (default: no)

## EXAMPLES

### Provision a new Ubuntu 11.10 VM using --vm-disk to import a local vmdk file.

    knife esx vm create --template-file ~/.chef/bootstrap/ubuntu11.10-gems.erb \
                        --vm-disk /path-to/ubuntu1110-x64-vmware-tools.vmdk \
                        --vm-name knife-esx-test-ubuntu \
                        --datastore datastore1
                        --esx-host my-test-host \
                        --esx-password secret

### Provision a new ubuntu 12.04 VM using --use-template to specify a template on the ESXi Host.

The command assumes that you have an ubuntu template located at /vmfs/volumes/datastore1/esx-gem/templates/ubuntu12.04-template-x64.vmdk.
In this example we also changed the location of the datastore from the default datastore1 to datastore2.

    knife esx vm create --esx-username root \
                        --vm-name ubuntu-12.04-vm \
                        --datastore datastore2 \
                        --esx-host server1 \
                        --esx-password secret \
                        --use-template ubuntu12.04-template-x64.vmdk

### Provision a new ubuntu 12.04 VM using --esx-templates-dir to specify a template directory on the ESXi host.

In this example, the template is located at /vmfs/volumes/datastore1/ubuntu12.04-template-x64/ubuntu12.04-template-x64.vmdk.

    knife esx vm create --esx-username root \
                        --vm-name ubuntu-12.04-vm \
                        --datastore datastore1 \
                        --esx-host server1 \
                        --use-template ubuntu12.04-template-x64.vmdk \
                        --esx-templates-dir /vmfs/volumes/datastore1/ubuntu12.04-template-x64
# LICENSE:

Author:: Sergio Rubio, Massimo Maino (<maintux@gmail.com>)
Copyright:: Copyright (c) 2011 Sergio Rubio, Massimo Maino
License:: Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
