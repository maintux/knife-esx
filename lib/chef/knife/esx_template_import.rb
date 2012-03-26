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
    class EsxTemplateImport < Knife

      include Knife::ESXBase

      banner "knife esx template import TEMPLATE_FILE"

      def run
        $stdout.sync = true
        @name_args.each do |vm_name|
          if not File.exist?(vm_name)
            ui.error("The file #{vm_name} does not exist.")
            exit 1
          end
          connection.import_template vm_name, :print_progress => true
        end
      end

    end
  end
end
