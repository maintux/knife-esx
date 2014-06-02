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
            :proc => Proc.new { |key| $param_key = key }

          option :esx_username,
            :long => "--esx-username USERNAME",
            :default => "root",
            :description => "Your ESX username (default 'root')",
            :proc => Proc.new { |username| $param_username = (username || 'root') }

          option :esx_host,
            :long => "--esx-host ADDRESS",
            :description => "Your ESX host address",
            :default => "127.0.0.1",
            :proc => Proc.new { |host| $param_host = host }

          option :free_license,
            :long => "--free-license",
            :description => "If your Hypervisor has a free license",
            :boolean => true,
            :default => false

          option :insecure,
            :long => "--insecure",
            :description => "Insecure connection",
            :boolean => true,
            :default => true

          option :esx_templates_dir,
            :long => "--esx-templates-dir TEMPLATES_DIRECTORY",
            :description => "Your ESX Templates directory",
            :default => "",
            :proc => Proc.new { |templates_dir| $param_templates_dir = templates_dir }

          ESXBase::commit_config # Apply config now, just in case it is needed now. Will re-apply when connecting.
        end
      end


      def self.commit_config()
        if $param_key != nil then Chef::Config[:knife][:esx_password] = $param_key end
        if $param_username != nil then Chef::Config[:knife][:esx_username] = $param_username end
        if $param_host != nil then Chef::Config[:knife][:esx_host] = $param_host end
        if $param_templates_dir != nil then Chef::Config[:knife][:esx_templates_dir] = $param_templates_dir end
      end

      def connection
        ESXBase.commit_config # write mixlib configuration now to ensure command line args override knife.rb settings
        if not @connection
          ui.info "#{ui.color("Connecting to ESX host #{config[:esx_host]}... ", :magenta)}"
          @connection = ESX::Host.connect(Chef::Config[:knife][:esx_host],
                                          Chef::Config[:knife][:esx_username],
                                          Chef::Config[:knife][:esx_password] || '',
                                          config[:insecure],
                                          {:templates_dir => Chef::Config[:knife][:esx_templates_dir], :free_license=>config[:free_license]})
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


