#
# Author:: Sergio Rubio (<rubiojr@frameos.org>)
# Copyright:: Sergio Rubio (c) 2011
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

require 'chef/knife'

class Chef
  class Knife
    module ESXBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'net/ssh/multi'
            require 'esx'
            require 'readline'
            require 'chef/json_compat'
            require 'terminal-table/import'
          end

          option :esx_password,
            :long => "--esx-password PASSWORD",
            :description => "Your ESX password",
            :proc => Proc.new { |key| Chef::Config[:knife][:esx_password] = key }

          option :esx_username,
            :long => "--esx-username USERNAME",
            :default => "root",
            :description => "Your ESX username (default 'root')",
            :proc => Proc.new { |username| Chef::Config[:knife][:esx_username] = (username || 'root') }

          option :esx_host,
            :long => "--esx-host ADDRESS",
            :description => "Your ESX host address",
            :default => "127.0.0.1",
            :proc => Proc.new { |host| Chef::Config[:knife][:esx_host] = host }

          option :esx_templates_dir,
            :long => "--esx-templates-dir TEMPLATES_DIRECTORY",
            :description => "Your ESX Templates directory",
            :default => "",
            :proc => Proc.new { |templates_dir| Chef::Config[:knife][:esx_templates_dir] = templates_dir }
        end
      end

      def connection
        Chef::Config[:knife][:esx_username] = 'root' if not Chef::Config[:knife][:esx_username]
        if not @connection
          ui.info "#{ui.color("Connecting to ESX host #{config[:esx_host]}... ", :magenta)}"
          @connection = ESX::Host.connect(Chef::Config[:knife][:esx_host],
                                          Chef::Config[:knife][:esx_username],
                                          Chef::Config[:knife][:esx_password] || '',
																					Chef::Config[:knife][:esx_templates_dir] || '')
        else
          @connection
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        Chef::Config[:knife][key] || config[key]
      end

    end
  end
end


