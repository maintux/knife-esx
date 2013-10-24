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
require 'open4'
require 'singleton'
require 'yaml'

module KnifeESX
  class DeployScript

    attr_reader :job_count

    # Sample job
    #---
    #:test1:
    #  'vm-memory':
    #  'extra-args':
    #  'esx-host':
    #  'template-file':
    #  'vm-disk':
    #  'ssh-user':
    #  'ssh-password':
    #  'run-list':
    #  'network-interface':
    def initialize(batch_file)
      @batch_file = batch_file
      @jobs = []
      @job_count = 0
      (YAML.load_file batch_file).each do |i|
        @jobs << DeployJob.new(i)
        @job_count += 1
      end
    end

    def each_job(&block)
      @jobs.each do |j|
        yield j
      end
    end

  end

  class DeployJob

    attr_reader :name

    def initialize(options)
      @name, @options = options
      validate
    end

    def validate
      if @name.nil? or @name.empty?
        raise Exception.new("Invalid job name")
      end
      if not @options['vm-disk'] or !File.exist?(@options['vm-disk'])
        raise Exception.new("Invalid VM disk for job #{@name}.")
      end
    end

    # returns [status, stdout, stderr]
    def run
      args = ""
      extra_args = ""
      @options.each do |k, v|
        if k == 'extra-args'
          extra_args << v
        else
          args << "--#{k} #{v} " unless k == 'extra-args'
        end
      end

      @out = ""
      @err = ""
      optstring = []
      @options.each do |k,v|
        optstring << "   - #{k}:".ljust(25) +  "#{v}\n" unless k =~ /password/
      end
      log_file = "/tmp/knife_esx_vm_create_#{@name.to_s.strip.chomp.gsub(/\s/,'_')}.log"
      Chef::Log.info "Bootstrapping VM #{@name} \n#{optstring.join}"
      Chef::Log.info "VM #{@name} bootstrap log: #{log_file}"
      @status = Open4.popen4("knife esx vm create --vm-name #{@name} #{args} #{extra_args} > #{log_file} 2>&1") do |pid, stdin, stdout, stderr|
        @out << stdout.read.strip
        @err << stderr.read.strip
      end
      if @status == 0
        Chef::Log.info "[#{@name}] deployment finished OK"
      else
        Chef::Log.error "[#{@name}] deployment FAILED"
        @err.each_line do |l|
          Chef::Log.error "[#{@name}] #{l.chomp}"
        end
      end
      return @status, @out, @err
    end

  end

end

class Chef
  class Knife

    class EsxVmCreate < Knife

      include Knife::ESXBase

      deps do
        require 'readline'
        require 'esx'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife esx vm create (options)"

      option :vm_disk,
        :long => "--vm-disk FILE",
        :description => "The path to the VMDK disk file"

      option :vm_name,
        :long => "--vm-name NAME",
        :description => "The Virtual Machine name"

      option :cpus,
        :long => "--vm-cpus CPUS",
        :description => "The Virtual Machine cpus (default: 1)"

      option :cpu_cores,
        :long => "--vm-cpu-cores CPU_CORES",
        :description => "The Virtual Machine cores per cpu (default: 1)"

      option :datastore,
        :long => "--datastore NAME",
        :default => 'datastore1',
        :description => "The Datastore to use for the VM files (default: datastore1)"

      option :guest_id,
        :long => "--guest-id NAME",
        :default => "otherGuest",
        :description => "The VM GuestID (default: otherGuest)"

      option :memory,
        :long => "--vm-memory MEM",
        :default => "512",
        :description => "The VM memory in MB (default: 512)"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'ubuntu10.04-gems'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
        :default => "ubuntu10.04-gems"

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :use_template,
        :long => "--use-template NAME",
        :description => "Try to use an existing template instead of importing disk",
        :default => nil

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) },
        :default => []

      option :json_attributes,
        :short => "-j JSON_ATTRIBUTES",
        :long => "--json-attributes JSON_ATTRIBUTES",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) },
        :default => {}

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username; default is 'root'",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_gateway,
        :short => "-G GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway"

      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :no_host_key_verify,
        :long => "--no-host-key-verify",
        :description => "Disable host key verification",
        :boolean => true,
        :default => false,
        :proc => Proc.new { true }

      option :vm_network,
        :long => "--vm-network network[,network..]",
        :description => "Network where nic is attached to",
        :default => 'VM Network'

      option :mac_address,
        :short => "-M mac[,mac..]",
        :long => "--mac-address",
        :description => "Mac address list",
        :default => nil

      option :skip_bootstrap,
        :long => "--skip-bootstrap",
        :description => "Skip bootstrap process (Deploy only mode)",
        :boolean => true,
        :default => false,
        :proc => Proc.new { true }

      option :async,
        :long => "--async",
        :description => "Deploy the VMs asynchronously (Ignored unless combined with --batch)",
        :boolean => true,
        :default => false,
        :proc => Proc.new { true }

      option :batch,
        :long => "--batch script.yml",
        :description => "Use a batch file to deploy multiple VMs",
        :default => nil

      def tcp_test_ssh(hostname)
        if config[:ssh_gateway]
          print "\n#{ui.color("Can't test connection through gateway, sleeping 10 seconds... ", :magenta)}"
          sleep 10
        else
          tcp_socket = TCPSocket.new(hostname, 22)
          readable = IO.select([tcp_socket], nil, nil, 5)
          if readable
            Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
            yield
            true
          else
            false
          end
        end
      rescue Errno::ETIMEDOUT, Errno::EPERM
        false
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH
        sleep 2
        false
      ensure
        tcp_socket && tcp_socket.close
      end

      def run
        $stdout.sync = true

        if config[:batch]
          Chef::Log.info "Running in batch mode. Extra arguments will be ignored."
          if not config[:async]
            counter = 0
            script = KnifeESX::DeployScript.new(config[:batch])
            script.each_job do |job|
              counter += 1
              status, stdout, stderr = job.run
              if status == 0
                Chef::Log.info 'Ok'
              else
                Chef::Log.error 'Failed'
                stderr.each_line do |l|
                  ui.error l
                end
              end
            end
          else
            Chef::Log.info "Asynchronous boostrapping selected"
            Chef::Log.info "Now do something productive while I finish my job ;)"
            script = KnifeESX::DeployScript.new(config[:batch])
            futures = []
            script.each_job do |job|
              futures << job.future(:run)
            end
            futures.each do |f|
              f.value
            end
          end
          return
        end

        if not config[:use_template]
          unless config[:vm_disk]
            ui.error("You have not provided a valid VMDK file. (--vm-disk)")
            exit 1
          end

          unless File.exist?(config[:vm_disk])
            ui.error("Invalid VMDK disk file (--vm-disk)")
            exit 1
          end
        end

        vm_name = config[:vm_name]
        if not vm_name
          ui.error("Invalid Virtual Machine name (--vm-name)")
          exit 1
        end


        datastore = config[:datastore]
        memory = config[:memory]
        cpus = config[:cpus]||1
        cpu_cores = config[:cpu_cores]||1
        vm_disk = config[:vm_disk]
        guest_id =config[:guest_id]
        destination_path = "/vmfs/volumes/#{datastore}/#{vm_name}"

        connection.remote_command "mkdir #{destination_path}"
        ui.info "Creating VM #{vm_name}"

        if config[:use_template]
          ui.info "Using template #{config[:use_template]}"
          if connection.template_exist?(config[:use_template])
            puts "#{ui.color("Cloning template...",:magenta)}"
            connection.copy_from_template config[:use_template], destination_path + "/#{vm_name}.vmdk"
          else
            ui.error "Template #{config[:use_template]} not found"
            exit 1
          end
        else
          puts "#{ui.color("Importing VM disk... ", :magenta)}"
          connection.import_disk vm_disk, destination_path + "/#{vm_name}.vmdk"
        end
        vm = connection.create_vm :vm_name => vm_name,
                             :datastore => datastore,
                             :disk_file => "#{vm_name}/#{vm_name}.vmdk",
                             :memory => memory,
                             :cpus => cpus,
                             :cpu_cores => cpu_cores,
                             :guest_id => guest_id,
                             :nics => create_nics(config[:vm_network], config[:mac_address])
        vm.power_on

        puts "#{ui.color("VM Created", :cyan)}"
        puts "#{ui.color("VM Name", :cyan)}: #{vm.name}"
        puts "#{ui.color("VM Memory", :cyan)}: #{(vm.memory_size.to_f/1024/1024).round} MB"

        return if config[:skip_bootstrap]

        # wait for it to be ready to do stuff
        print "\n#{ui.color("Waiting server... ", :magenta)}"
        timeout = 100
        found = connection.virtual_machines.find { |v| v.name == vm.name }
        loop do
          if not vm.ip_address.nil? and not vm.ip_address.empty?
            puts "\n#{ui.color("VM IP Address: #{vm.ip_address}", :cyan)}"
            break
          end
          timeout -= 1
          if timeout == 0
            ui.error "Timeout trying to reach the VM. Does it have vmware-tools installed?"
            exit 1
          end
          sleep 1
          found = connection.virtual_machines.find { |v| v.name == vm.name }
        end

        print "\n#{ui.color("Waiting for sshd... ", :magenta)}"
        print(".") until tcp_test_ssh(vm.ip_address) { sleep @initial_sleep_delay ||= 10; puts(" done") }
        bootstrap_for_node(vm).run

        puts "\n"
        puts "#{ui.color("Name", :cyan)}: #{vm.name}"
        puts "#{ui.color("IP Address", :cyan)}: #{vm.ip_address}"
        puts "#{ui.color("Environment", :cyan)}: #{config[:environment] || '_default'}"
        puts "#{ui.color("Run List", :cyan)}: #{config[:run_list].join(', ')}"
        puts "#{ui.color("Done!", :green)}"
      end

      def bootstrap_for_node(vm)
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [vm.ip_address]
        bootstrap.config[:async] = config[:async]
        bootstrap.config[:run_list] = config[:run_list]
        bootstrap.config[:first_boot_attributes] = config[:json_attributes]
        bootstrap.config[:ssh_user] = config[:ssh_user]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = config[:chef_node_name] || vm.name
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:distro] = locate_config_value(:distro)
        # bootstrap will run as root...sudo (by default) also messes up Ohai on CentOS boxes
        bootstrap.config[:use_sudo] = true unless config[:ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
        bootstrap.config[:ssh_password] = config[:ssh_password]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap
      end

      def create_nics(networks, macs)
        net_arr = networks.split(/,/).map { |x| { :network => x } }
        if macs
          mac_arr = macs.split(/,/)
          net_arr.each_index { |x| net_arr[x][:mac_address] = mac_arr[x] if mac_arr[x] and !mac_arr[x].empty? }
        else
          net_arr
        end
      end
    end
  end
end
