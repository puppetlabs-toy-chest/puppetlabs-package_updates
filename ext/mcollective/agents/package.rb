module MCollective
    module Agent
        # An agent that uses Reductive Labs Puppet to manage packages
        #
        # See http://code.google.com/p/mcollective-plugins/
        #
        # Released under the terms of the GPL, same as Puppet
        class Package<RPC::Agent
            metadata    :name        => "SimpleRPC Agent For Package Management",
                        :description => "Agent To Manage Packages",
                        :author      => "R.I.Pienaar",
                        :license     => "Apache 2",
                        :version     => "1.4",
                        :url         => "http://projects.puppetlabs.com/projects/mcollective-plugins/wiki",
                        :timeout     => 180

            ["install", "update", "uninstall", "purge", "status"].each do |act|
                action act do
                    validate :package, :shellsafe
                    do_pkg_action(request[:package], act.to_sym)
                end
            end

            action "yum_clean" do
                reply.fail! "Cannot find yum at /usr/bin/yum" unless File.exist?("/usr/bin/yum")
                if respond_to?(:run)
                    reply[:exitcode] = run("/usr/bin/yum clean all", :stdout => :output, :chomp => true)
                else
                    reply[:output] = %x[/usr/bin/yum clean all]
                    reply[:exitcode] = $?.exitstatus
                end

                reply.fail! "Yum clean failed, exit code was #{reply[:exitcode]}" unless reply[:exitcode] == 0
            end

            action "apt_update" do
                reply.fail! "Cannot find apt-get at /usr/bin/apt-get" unless File.exist?("/usr/bin/apt-get")
                if respond_to?(:run)
                    reply[:exitcode] = run("/usr/bin/apt-get update", :stdout => :output, :chomp => true)
                else
                    reply[:output] = %x[/usr/bin/apt-get update]
                    reply[:exitcode] = $?.exitstatus
                end

                reply.fail! "apt-get update failed, exit code was #{reply[:exitcode]}" unless reply[:exitcode] == 0
            end

            action "checkupdates" do
                begin
                  #Try to load Faces and make sure the :package Face is available
                  #Resort to using package systems if we get a LoadError
                  require 'puppet/face'

                  unless Puppet::Face.faces.include? :package
                    raise LoadError
                  end

                  reply[:package_manager] = "N/A - Using Puppet Package Face"

                  #Get the updates and reformat it in to an array of hashes
                  reply[:outdated_packages] = Puppet::Face[:package, '0.0.1'].updates.map do |name,package|
                    package[:package] = name
                    package[:version] = package[:update]
                    package[:repo]    = 'UNKNOWN'
                    package
                  end
                rescue LoadError
                  if File.exist?("/usr/bin/yum")
                    reply[:package_manager] = "yum"
                    yum_checkupdates_action
                  elsif File.exist?("/usr/bin/apt-get")
                    reply[:package_manager] = "apt"
                    apt_checkupdates_action
                  else
                    reply.fail! "Cannot find a compatible package system to check updates for"
                  end
                end
            end

            action "yum_checkupdates" do
                reply.fail! "Cannot find yum at /usr/bin/yum" unless File.exist?("/usr/bin/yum")
                if respond_to?(:run)
                    reply[:exitcode] = run("/usr/bin/yum -q check-update", :stdout => :output, :chomp => true)
                else
                    reply[:output] = %x[/usr/bin/yum -q check-update]
                    reply[:exitcode] = $?.exitstatus
                end

                if reply[:exitcode] == 0
                    reply[:outdated_packages] = []
                # Exit code 100 means package updates available
                elsif reply[:exitcode] == 100
                    reply[:outdated_packages] = do_yum_outdated_packages(reply[:output])
                else
                    reply.fail! "Yum check-update failed, exit code was #{reply[:exitcode]}"
                end
            end

            action "apt_checkupdates" do
                reply.fail! "Cannot find apt at /usr/bin/apt-get" unless File.exist?("/usr/bin/apt-get")
                if respond_to?(:run)
                    reply[:exitcode] = run("/usr/bin/apt-get --simulate dist-upgrade", :stdout => :output, :chomp => true)
                else
                    reply[:output] = %x[/usr/bin/apt-get --simulate dist-upgrade]
                    reply[:exitcode] = $?.exitstatus
                end
                reply[:outdated_packages] = []

                if reply[:exitcode] == 0
                    reply[:output].each_line do |line|
                        next unless line =~ /^Inst/

                        # Inst emacs23 [23.1+1-4ubuntu7] (23.1+1-4ubuntu7.1 Ubuntu:10.04/lucid-updates) []
                        if line =~ /Inst (.+?) \[.+?\] \((.+?)\s(.+?)\)/
                                reply[:outdated_packages] << {:package => $1.strip,
                                                              :version => $2.strip,
                                                              :repo => $3.strip}
                        end
                    end
                else
                    reply.fail! "APT check-update failed, exit code was #{reply[:exitcode]}"
                end
            end

            private
            def do_pkg_action(package, action)
                begin
                    require 'puppet'

                    if ::Puppet.version =~ /0.24/
                        ::Puppet::Type.type(:package).clear
                        pkg = ::Puppet::Type.type(:package).create(:name => package).provider
                    else
                        pkg = ::Puppet::Type.type(:package).new(:name => package).provider
                    end

                    reply[:output] = ""
                    reply[:properties] = "unknown"

                    case action
                        when :install
                            reply[:output] = pkg.install if pkg.properties[:ensure] == :absent

                        when :update
                            begin
                              require 'puppet/face'

                              unless Puppet::Face.faces.include? :package
                                raise LoadError
                              end

                              reply[:output] = Puppet::Face[:package, '0.0.1'].update package
                            rescue LoadError
                              reply[:output] = pkg.update unless pkg.properties[:ensure] == :absent
                            end

                        when :uninstall
                            reply[:output] = pkg.uninstall unless pkg.properties[:ensure] == :absent

                        when :status
                            pkg.flush
                            reply[:output] = pkg.properties

                        when :purge
                            reply[:output] = pkg.purge

                        else
                            reply.fail "Unknown action #{action}"
                    end

                    pkg.flush
                    reply[:properties] = pkg.properties
                rescue Exception => e
                    reply.fail e.to_s
                end
            end

            def do_yum_outdated_packages(packages)
                outdated_pkgs = []
                packages.strip.each_line do |line|
                    # Don't handle obsoleted packages for now
                    break if line =~ /^Obsoleting\sPackages/i

                    pkg, ver, repo = line.split
                    if pkg && ver && repo
                        pkginfo = { :package => pkg.strip,
                                    :version => ver.strip,
                                    :repo => repo.strip
                                  }
                        outdated_pkgs << pkginfo
                    end
                end
                outdated_pkgs
            end
        end
    end
end

# vi:tabstop=4:expandtab:ai:filetype=ruby

