module UBNT
  class Configuration
    class NotValid < Exception
    end

    attr_accessor :config

    attr_accessor :hardware_type
    attr_accessor :wpa_mode
    attr_accessor :ssid
    attr_accessor :users
    attr_accessor :root_password_hash
    attr_accessor :ssh_keys
    attr_accessor :dns_recursors
    attr_accessor :ntp_servers
    attr_accessor :spectrum_bandwidth
    attr_accessor :frequency

    # FIXME: get exhaustive lists for these things
    HARDWARE_TYPES = [ "Nanostation Loco M5" ]
    MODULATION_AND_CODING_SCHEMES = [ 15 ]
    IEEE_80211_RF_MODES = [ "11NAHT20", "11NAHT40", "11NAHT40PLUS", "11NAHT40MINUS",
                            "11NGHT20", "11NGHT40" ]
    FIVE_GHZ_FREQUENCIES = (5745 .. 5805)
    TWO_GHZ_FREQUENCIES = (0 .. 0)
    #
    HARDWARE_RADIO_FREQUENCIES = { "Nanostation Loco M5" => [ FIVE_GHZ_FREQUENCIES ] }
    HARDWARE_RADIO_MODES =       { "Nanostation Loco M5" => [ "11NAHT20", "11NAHT40", "11NAHT40PLUS", "11NAHT40MINUS" ] }
    HARDWARE_SPECTRAL_WIDTHS =   { "Nanostation Loco M5" => [ 5, 10, 20, 40 ] } 

    def initialize(hardware_type, config = {})
      @hardware_type = hardware_type
      @config = Hash.new
      # Start with the factory-default configuration
      @config.merge(factory_default)
      @config.merge(config) if config.length > 0

      raise ArgumentError("Hardware type #{hardware_type} is not valid") unless HARDWARE_TYPES.include?(hardware_type)

      # Define getter and setter methods for simple, one-line directives
      [ 
        ['hostname', 'resolv.host.1.name'],
        ['ssid',     'wireless.1.ssid'],
        ['snmp_location', 'snmp.location'],
        ['snmp_contact', 'snmp.contact'],
        ['snmp_community', 'snmp.community'],
        ['default_gateway', 'route.1.gateway'],
        ['rf_mcs', 'radio.1.rate.mcs'],
        ['rf_mode', 'radio.1.ieee_mode'],
        ['rf_frequency', 'radio.1.freq'],
        ['rf_ack_timeout', 'radio.1.acktimeout'],
        ['rf_ack_distance', 'radio.1.ackdistance'],
        ['ip', 'netconf.3.ip'],
        ['netmask', 'netconf.3.netmask'],
        ['default_gateway', 'route.1.gateway'],
      ].each do |name, directive|
        define_method(name.to_sym) { config[directive] }
        define_method(name+'='.to_sym) do |value|
          config[directive] = value
        end
      end

      # One-line, enabled/disabled knobs
      [
        ['autoip', 'netconf.3.autoip.status' ],
        ['filter_eapol', 'ebtables.3.status' ],
      ].each do |name, directive|
        define_method(name.to_sym) do
          case config[directive]
          when "enabled"
            true
          when "disabled"
          else
            nil
          end
        end
        define_method(name+'='.to_sym) do |value|
          if value then
            config[directive] = "enabled"
          else
            config[directive] = "disabled"
        end
      end

    end # def initialize



    # clksel almost seems like a frequency or spectral-width divider of some sort.
    # cwm seems to indicate if bandwidth multiplication should occur
    #
    # bandwidth seems to be set by "radio.1.clksel"
    # 1 -- 40 Mhz
    # 1 -- 20 Mhz
    # 2 -- 10 Mhz
    # 4 -- 5  Mhz
    #
    # radio.1.cwm.mode
    # 2 -- 40 Mhz
    # 1 -- in the default configuration (20 Mhz?)
    # 0 -- 20 Mhz
    # 0 -- 10 Mhz
    # 0 -- 5  Mhz
    #
    # if radio.N.freq is "0", with 40 Mhz channels, the plus/minus can be left off. It's selected automatically (lower for every frequency, except the last)

    # Set the transmission and reception bandwidth, in Mhz
    def bandwidth(mhz)
      @spectrum_bandwidth = mhz
      determine_rf_mode
    end

    def spectrum_bandwidth=(width)
      compatible_widths = HARDWARE_SPECTRAL_WIDTHS[hardware_type]
      unless compatible_widths.include?(width) then
        raise NotValid.new("Spectrum width #{width} is not one of #{compatible_widths.inspect}")
      end
      @spectrum_bandwidth = width
    end

    def determine_rf_mode
      # frequency and spectral width determines mode
      #
      # if frequency and bandwidth are set, see if the lower step in the frequency range is available, if not check the upper step and assign that, if the lower one is available, take that
      # if the frequency is set, use the default mode and apply the above logic
      # if the spectral width, but not frequency is set, set the freq to zero but don't set plus/minus

      if frequency == 0 then
        return ""
      end

      if spectrum_bandwidth == 20 then
        return "11NAHT20"
      end

      if frequency and spectrum_bandwidth then

        hardware_ranges = HARDWARE_RADIO_FREQUENCIES[hardware_type]
        desired_frequency_range = hardware_ranges.select { |range| range.include?(frequency) }.first
        unless desired_frequency_range then
          raise NotValid.new("Configured frequency #{frequency} not valid for hardware type of #{hardware_type}.")
        end

        frequency_table_index = desired_frequency_range.step(spectrum_bandwidth).index(frequency)
        if frequency_table_index == 0 then # We're at the bottom of the spectrum
          mode = upper
          
        else # We're somewhere in the middle or at the upper end
          mode = lower
        end

      else
      end

    end

    def mcs
    end

    def spectrum_bandwidth
    end

    def self.factory_default
      {
        "bridge.1.devname" => "br0",
        "bridge.1.fd" => "1",
        "bridge.1.port.1.devname" => "eth0",
        "bridge.1.port.2.devname" => "ath0",
        "bridge.1.port.3.devname" => "eth1",
        "bridge.status" => "enabled",
        "dhcpc.1.devname" => "br0",
        "dhcpc.1.status" => "enabled",
        "dhcpc.status" => "disabled",
        "dhcpd.1.status" => "disabled",
        "dhcpd.status" => "disabled",
        "ebtables.1.cmd" => "-t nat -A PREROUTING --in-interface ath0 -j arpnat --arpnat-target ACCEPT",
        "ebtables.1.status" => "enabled",
        "ebtables.2.cmd" => "-t nat -A POSTROUTING --out-interface ath0 -j arpnat --arpnat-target ACCEPT",
        "ebtables.2.status" => "enabled",
        "ebtables.3.cmd" => "-t broute -A BROUTING --protocol 0x888e --in-interface ath0 -j DROP",
        "ebtables.3.status" => "enabled",
        "ebtables.status" => "enabled",
        "httpd.status" => "enabled",
        "netconf.1.devname" => "eth0",
        "netconf.1.ip" => "0.0.0.0",
        "netconf.1.netmask" => "255.255.255.0",
        "netconf.1.promisc" => "enabled",
        "netconf.1.status" => "enabled",
        "netconf.1.up" => "enabled",
        "netconf.2.allmulti" => "enabled",
        "netconf.2.devname" => "ath0",
        "netconf.2.ip" => "0.0.0.0",
        "netconf.2.netmask" => "255.255.255.0",
        "netconf.2.promisc" => "enabled",
        "netconf.2.status" => "enabled",
        "netconf.2.up" => "enabled",
        "netconf.3.devname" => "br0",
        "netconf.3.ip" => "192.168.1.20",
        "netconf.3.netmask" => "255.255.255.0",
        "netconf.3.status" => "enabled",
        "netconf.3.up" => "enabled",
        "netconf.status" => "enabled",
        "radio.1.ack.auto" => "enabled",
        "radio.1.ackdistance" => "600",
        "radio.1.acktimeout" => "31",
        "radio.1.antenna" => "4",
        "radio.1.clksel" => "1",
        "radio.1.cwm.enable" => "0",
        "radio.1.cwm.mode" => "1",
        "radio.1.devname" => "ath0",
        "radio.1.dfs.status" => "enabled",
        "radio.1.freq" => "0",
        "radio.1.ieee_mode" => "auto",
        "radio.1.low_txpower_mode" => "disabled",
        "radio.1.mode" => "Managed",
        "radio.1.obey" => "enabled",
        "radio.1.polling" => "enabled",
        "radio.1.pollingnoack" => "0",
        "radio.1.pollingpri" => "",
        "radio.1.reg_obey" => "enabled",
        "radio.1.status" => "enabled",
        "radio.1.txpower" => "28",
        "radio.countrycode" => "840", # United States / FCC
        "radio.status" => "enabled",
        "resolv.host.1.name" => "ubnt",
        "route.1.devname" => "br0",
        "route.1.gateway" => "192.168.1.1",
        "route.1.ip" => "0.0.0.0",
        "route.1.netmask" => "0",
        "route.1.status" => "enabled",
        "route.status" => "enabled",
        "sshd.port" => "22",
        "sshd.status" => "enabled",
        "users.1.name" => "ubnt",
        "users.1.password" => "VvpvCwhccFv6Q",
        "users.1.status" => "enabled",
        "users.status" => "enabled",
        "wireless.1.addmtikie" => "enabled",
        "wireless.1.devname" => "ath0",
        "wireless.1.hide_ssid" => "disabled",
        "wireless.1.security" => "none",
        "wireless.1.ssid" => "ubnt",
        "wireless.1.status" => "enabled",
        "wireless.status" => "enabled",
        "aaa.status" => "disabled",
        "wpasupplicant.status" => "disabled",
        "wpasupplicant.device.1.status" => "disabled",
      }
    end

    # TODO
    def diff(config)
    end

    def parse(string)
      string.split("\n").each do |line|
        if parts = line.split("=") and parts.length == 2 then
          @config[parts.first] = parts.last
        end
      end
    end

    def valid?
      # If you're using WPA, an SSID and a PSK needs to be set.
      if wpa_mode == ( 'authenticator' || 'supplicant' )) then
        if ssid.nil? or wpa_psk.nil? then
          raise NotValid
        end
      end

      # If additional users are defined, do they all have password hashes set?
      if users.is_a?(Array) then
        users.each do |user, password_hash|
          if user.nil? || user.length > 0 then
            raise NotValid.new("Username \"#{user}\" can't be zero characters")
          elsif password_hash.nil? || password_hash.length > 0 then
            raise NotValid.new("Password hash for \"#{user}\" can't be zero characters")
          end
        end
      end

      # If defined, SSH keys need to have a type, value, and a comment
      if ssh_keys.is_a?(Array) then
        ssh_keys.each do |key|
          unless ( 
                  key[0].match(/ssh-(rsa|dsa)/) &&
                  key[1].is_a?(String) &&
                  key[1].length > 0 &&
                  key[2].is_a?(String) &&
                  key[2].length > 0 &&
                 ) then
                 raise NotValid.new("SSH keys must have a type, value, and a comment")
          end
        end
      end
    end

    def delete_config_starting_with(prefix)
      config.each do |key,value|
        if key.to_s.start_with?(prefix) then
          @config.delete(key)
        end
      end
    end


    def wpa_mode
      @wpa_mode
    end
    def wpa_mode=(mode)
      case mode
      when 'authenticator'
        delete_config_starting_with("aaa.")
        delete_config_starting_with("wpasupplicant.")

        @config["aaa.status"] = "enabled"
        @config["aaa.1.ssid"] = ssid
        @config["aaa.1.wpa.psk"] = wpa_psk
        @config["aaa.1.status"] = "enabled"
        @config["aaa.1.br.devname"] = "br0"
        @config["aaa.1.devname"] = "ath0"
        @config["aaa.1.driver"] = "madwifi"
        @config["aaa.1.radios.auth.1.status"] = "disabled"
        @config["aaa.1.wpa.1.pairwise"] = "CCMP"
        @config["aaa.1.wpa.key.1.mgmt"] = "WPA-PSK"
        @config["aaa.1.wpa"] = "2"

      when 'supplicant'
        delete_config_starting_with("aaa.")
        delete_config_starting_with("wpasupplicant.")
      end
    end

  end

end
