require 'socket'
require 'rubygems'
require 'packetfu'

module UBNT
  class Locator
    # Use arping to find deafult configured devices. This only really makes sense
    # if you have a bunch of unconfigured devices that you want to enumerate.
    def self.locate(options = {})
      discovery_method = options[:discovery_method] || :arp
      raise ArgumentError.new('Interface name required') if discovery_method == :arp and not options[:interface_name]
      interface_name = options[:interface_name] or nil
      ip = options[:ip] or "192.168.1.20"

      case discovery_method
      when :arp
        arping_output = `arping`
        if $?.exitcode == 127 then
          puts "Couldn't execute arping. Is it installed?"
        end

        if arping_output =~ /Thomas Habets/ then
          arping_type = 'habets'
        else
          arping_type = 'iputils'
        end

        case arping_type
        when 'iputils'
          output = `arping -I #{interface_name} -c 15 #{ip}`
          macs = output.split("\n").select{ |line| line =~ /cast reply from .* \[/ }.map{ |line| line.split[4].delete('[]') }.sort.uniq
        when 'habets'
          output = `arping -i #{interface_name} -c 15 #{ip}`
          macs = output.split("\n").select{ |line| line =~ /bytes from .* index=/ }.map{ |line| line.split[3] }.sort.uniq
        end

        devices = []
        macs.each do |mac|
          devices << UBNT::Device.new(:ip => ip, :static_arp_needed => true, :mac => mac, :management_interface => interface_name)
        end
        return devices
      when :udp # Ubiquiti-proprietary UDP discovery packets
        sock = UDPSocket.new
        sock.bind '0.0.0.0', 0
        sock.send "\x01\x00\x00\x00", 0, '255.255.255.255', 10001
        return []
        
        #UDPDiscoveryProbe.new.to_w(interface_name)
      end # case @discovery_method
    end # def locate

  end # class Locator
  class UDPDiscoveryProbePacket < PacketFu::UDPPacket
    def initialize()
      super
      # FIXME: This is the only value I've observed in probe discovery.
      #   Is there something more to this side of the protocol?
      self.payload = "\x01\x00\x00\x00"
      @eth_header.eth_daddr = 'ff:ff:ff:ff:ff:ff'
      @ip_header.ip_daddr = '255.255.255.255'
      @udp_header.udp_dst = 10001
      self.recalc
    end
  end # class UDPDiscoveryProbe
end # module UBNT

if $0 == __FILE__ then
  p UBNT::Locator.locate(:discovery_method => :udp)
end
