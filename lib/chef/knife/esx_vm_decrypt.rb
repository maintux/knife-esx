#
# Author:: Victor Hahn (<info@victor-hahn.de>)
# Copyright:: Flexoptix GmbH
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife/esx_base'
require 'net/ssh'

class Chef
  class Knife

    class EsxVmDecrypt < Knife

      include Knife::ESXBase

      banner "knife esx vm decrypt (options)"

      option :vm_name,
        :long => "--vm-name NAME",
        :description => "VM to decrypt"

      option :encrypted_root,
        :long => "--encrypted-root PASSWORD",
	:description => "If the disk image has an encrypted root file system decrypt before bootstrap. This only works if your disk image is set up for decryption via SSH and has VMWare tools in initrd."

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password to use for decryption."

      # Options for other kinds of decryption jobs should be added here

      def run
        if not config[:vm_name]
          ui.error "Need to specify a virtual machine (--vm-name)" 
          exit 1
        end

        if not config[:encrypted_root] # or config[:some_other_encryption_option] or ...
          ui.error "Need to specify password"
        end

        vm = connection.get_vm config[:vm_name]
        if vm == nil
          ui.error "Specified VM not found. Double check --vm-name?"
          exit 1
        end

        vm.power_on

	EsxVmDecrypt.decrypt self, vm, "root", config[:ssh_password], config[:encrypted_root]
      end
      
      
      def self.decrypt this, vm, user="root", sshpass, cryptpass # allow this function to be called from other ESXBase objects
	this.wait_for_ssh vm
	ssh = Net::SSH.start vm.ip_address, "root", :password => sshpass
	if ssh.closed?
	  ui.error "Could not establish SSH connection to decrypt root. Did you use a virtual disk image that features an SSH server in initrd?"
	  exit 1
	end

	result = ssh.exec! "ls -l /lib/cryptsetup/passfifo"
	if result =~ /^p.*\/lib\/cryptsetup\/passfifo\n$/
          command = 'echo -n "' + cryptpass + '" > /lib/cryptsetup/passfifo'
	  result = ssh.exec! command
	  sleep 2 # allow the server some time to decrypt and chroot
	else
	  ui.error "The server does not seem to ask for a password to decrypt root. /lib/cryptsetup/passfifo does not exist."
	  ui.error "Please note that plymouth (as prominently featured in Ubuntu) does not currently support remote decryption."
	  exit 1
	end
      end

    end
  end
end
