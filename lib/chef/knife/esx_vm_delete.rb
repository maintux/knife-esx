#
# Author:: Sergio Rubio (<rubiojr@frameos.org>)
# Copyright:: Copyright (c) 2011 Sergio Rubio
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

class Chef
  class Knife
    class EsxVmDelete < Knife

      include Knife::ESXBase

      banner "knife esx vm delete VM_NAME [VM_NAME] (options)"

      option :force_delete,
        :long => "--force-delete NO",
        :default => 'no',
        :description => "Do not confirm VM deletion when yes"

      def run
        deleted = []
        connection.virtual_machines.each do |vm|
          @name_args.each do |vm_name|
            if vm_name == vm.name
              if config[:force_delete] != 'yes'
                confirm("Do you really want to delete this virtual machine '#{vm.name}'")
              end

              vm.power_off if (vm.name =~ /#{vm.name}/ and vm.power_state == 'poweredOn')
              vm.destroy
              deleted << vm_name
              ui.warn("Deleted virtual machine #{vm.name}")
            end
          end
        end
        @name_args.each do |vm_name|
          ui.warn "Virtual Machine #{vm_name} not found" if not deleted.include?(vm_name)
        end
      end

    end
  end
end
