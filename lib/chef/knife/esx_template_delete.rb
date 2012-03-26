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
    class EsxTemplateDelete < Knife

      include Knife::ESXBase

      banner "knife esx template delete TEMPLATE_NAME [TEMPLATE_NAME] (options)"

      option :force_delete,
        :long => "--force-delete NO",
        :default => 'no',
        :description => "Do not confirm VM deletion when yes"

      def run
        deleted = []
        connection.list_templates.each do |tmpl|
          @name_args.each do |tmpl_name|
            if tmpl_name == File.basename(tmpl)
              if config[:force_delete] !~ /true|yes/i
                confirm("Do you really want to delete this template '#{tmpl_name}'")
              end
              connection.delete_template tmpl_name
              deleted << tmpl_name
              ui.info("Deleted template #{tmpl_name}")
            end
          end
        end
        @name_args.each do |tmpl_name|
          ui.warn "Template #{tmpl_name} not found" if not deleted.include?(tmpl_name)
        end
      end

    end
  end
end
