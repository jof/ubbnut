module UBNT
  class Locator
    # Use arping to find deafult configured devices. This only really makes sense
    # if you have a bunch of unconfigured devices that you want to enumerate.
    def self.locate(method = :arp, options = {})
      raise ArgumentError.new('Interface name required') if method == :arp and not options[:interface_name]
      interface_name = options[:interface_name] or nil
      ip = options[:ip] or "192.168.1.20"

      case method
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
      end # case @method
    end # def locate

  end # class Locator
end # module UBNT
