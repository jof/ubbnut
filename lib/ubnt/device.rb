module UBNT
  class Device
    attr_accessor :config

    def initialize(options = {})
      @config = options[:config] or UBNT::Configuration.new
      @ip = config[:ip] or raise ArgumentError
      @user = config[:user] or "ubnt"
      @password = config[:password] or "ubnt"

      @static_arp_needed = (true if options[:static_arp_needed]) || false
      @mac = config[:mac] or nil
      @management_interface = config[:management_interface] or nil
      if @static_arp_needed and not ( @mac and @management_interface ) then raise ArgumentError("A device that needs static ARP also needs a MAC and management interface")

      @ssh_connection = nil
    end

    def connect
      UBNT::StaticARP.set_arp(@ip, @mac, @management_interface) if @static_arp_needed

      if not @ssh_connection.is_a?(Net::SSH::Connection::Session) or @ssh_connection.closed? then
        @ssh_connection = Net::SSH.start(@ip, @user, { :password => @password })
      end

      # Return true if there's a live connection
      !@ssh_connection.closed?
    end

    def cleanup
      @ssh_connection.close
      UBNT::StaticARP.delete_arp(@ip, @mac, @management_interface) if @static_arp_needed
    end

    def validate
      @config.is_a?(UBNT::Configuration)
    end

    # Put the config into place on the remote FS.
    def place_config
      if self.validate and self.connect then
        @ssh_connection.scp.upload!(StringIO.new(@config.to_s), "/tmp/system.cfg")
      end
    end

    def apply_config!
      if self.connect then
        @ssh_connection.exec!("/usr/etc/rc.d/rc.softrestart") or raise
        #@ssh_connection.exec!("ubntconf -c /tmp/system.cfg") or raise
        #@ssh_connection.exec!("cfgmtd -p /etc/") or raise
        #@ssh_connection.exec!("reboot") or raise
      end
    end

    # Put the config into place on the remote FS and apply it as well.
    def push!
      self.place_config
      self.apply_config!
    end

    def pull
      if self.connect then
        @config = UBNT::Configuration.parse(@ssh_connection.scp.download!("/tmp/system.cfg"))
      end
    end
  end # class Device
end
