#
# Author:: Sergio Rubio, Massimo Maino (<maintux@gmail.com>)
# Copyright:: Sergio Rubio, Massimo Maino (c) 2011
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
    class EsxVmList < Knife

      include Knife::ESXBase

      banner "knife esx vm list (options)"

      def run
        $stdout.sync = true
        vm_table = table do |t|
          t.headings = %w{NAME IPADDR POWER_STATE VMW_TOOLS}
          connection.virtual_machines.each do |vm|
            t << [vm.name, vm.ip_address, vm.power_state, vm.guest_info.vmware_tools_installed?]
          end
        end
        puts vm_table
      end
    end
  end
end
