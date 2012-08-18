module UBNT
  class Device

    attr_accessor :config
    attr_accessor :hardware_type

    # Create an instance of a device descriptor. Currently, this
    # requires an IP at initialization-time in order to be able to reach
    # and interact with the device.
    def initialize(hardware_type, options = {})
      @hardware_type = hardware_type

      unless HARDWARE_TYPES.include?(@hardware_type) then
        raise NotValidHardware.new("The requested hardware type is non-existant or not defined.")
      end
      unless options[:ip] then
        raise ArgumentError.new("An IP address for reaching the device is required.")
      end

      @config = options[:config] || UBNT::Configuration.new(@hardware_type)
      @ip = options[:ip] || "192.168.1.20"
      @user = options[:user] || "ubnt"
      @password = options[:password] || "ubnt"

      @static_arp_needed = (true if options[:static_arp_needed]) || false
      @mac = options[:mac] || nil
      @management_interface = options[:management_interface] || nil
      if @static_arp_needed and not ( @mac and @management_interface ) then raise ArgumentError("A device that needs static ARP also needs a MAC and management interface")

        @ssh_connection = nil
      end
    end


      def valid?
        @config.is_a?(UBNT::Configuration) && @config.valid?
      end

      # TODO
      def reachable?
      end

      # Put the config into place on the remote filesystem.
      def place_config
        if self.valid? and self.connect then
          @ssh_connection.scp.upload!(StringIO.new(@config.to_s), "/tmp/system.cfg")
        end
      end

      def push
        self.place_config
      end

      # Put the configuration into place on the remote filesystem *and*
      # apply it.
      def push!
        self.place_config
        self.apply_config!
      end

      # Apply the configuration that's in place. This could involve rebooting.
      def apply_config!
        if self.connect then
          @ssh_connection.exec!("/usr/etc/rc.d/rc.softrestart") or raise
          #@ssh_connection.exec!("ubntconf -c /tmp/system.cfg") or raise
          #@ssh_connection.exec!("cfgmtd -p /etc/") or raise
          #@ssh_connection.exec!("reboot") or raise
        end
      end

      # Pull the configuration from the device and parse it.
      def pull
        if self.connect then
          @config = UBNT::Configuration.parse(@ssh_connection.scp.download!("/tmp/system.cfg"))
        end
      end



      private
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

  end # class Device
end # module UBNT
