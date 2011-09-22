module UBNT
  class Provisioner
    def initialize(interface, configuration)
      @interface = interface
      @configuration = configuration
      @macs = UBNT::ARPLocator.locate(interface)

      @macs.each do |mac|
        update_arp mac
        unless can_login? then
          STDERR.puts "I can't seem to login to #{mac}"
        end

        # Any loops go here. hostnames, ips, etc
        generate_configuration

        upload_configuration
        apply_configuration
        reboot
      end
      delete_arp

    end

    def update_arp(mac)
      case `uname`.strip
      when /linux/i
        `sudo arp -i #{@interface} -s 192.168.1.20 #{mac}`
      when /bsd/i
        `sudo arp -s 192.168.1.20 #{mac} ifscope #{@interface}`
      when /darwin/i
        `sudo arp -s 192.168.1.20 #{mac} ifscope #{@interface}`
      end
    end
    def delete_arp
      case `uname`.strip
      when /linux/i
        `sudo arp -i #{@interface} -d 192.168.1.20`
      when /bsd/i, /darwin/i
        `sudo arp -d 192.168.1.20 ifscope #{@interface}`
      end
    end

    def can_login?
      success = True
      begin
        Net::SSH.start('192.168.1.20', 'ubnt', :password => 'ubnt') do |ssh|
        end

      rescue Net::SSH::Exception, SocketError => e
        success = False
      end
      success
    end

    def upload_configuration
      # scp config to /tmp/system.cfg
      temporary_file = Tempfile.new('ubnt_provisioning')
      path = temporary_file.path
      temporary_file.write(@configuration.to_s)
      temporary_file.close

      Net::SCP.upload(path, '/tmp/system.cfg')
    end

    def apply_configuration
      #  run ubntconf
      #  run mtdcfg
      Net::SSH.start('192.168.1.20') do |ssh|
        ssh.exec("ubntconf -c /tmp/system.cfg")
        ssh.exec("cfgmtd -w -p /etc/")
      end
    end

    def reboot
      Net::SSH.start('192.168.1.20') do |ssh|
        ssh.exec("reboot")
      end
    end

  end
end
