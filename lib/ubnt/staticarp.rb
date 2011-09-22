module UBNT
  class StaticARP
    def set_arp(ip, mac, management_interface)
      case `uname`.strip
      when /linux/i
        fork { exec("arp -i #{management_interface} -s #{ip} #{mac}") }
      when /bsd/i
        fork { exec("arp -s #{ip} #{mac}") }
      when /darwin/i
        fork { exec("arp -s #{ip} #{mac} ifscope #{management_interface}") }
      end
    end

    def delete_arp(ip, mac, management_interface)
      case `uname`.strip
      when /linux/i
        fork { exec("arp -i #{management_interface} -d #{ip}") }
      when /bsd/i
        fork { exec("arp -d #{ip}") }
      when /darwin/i
        fork { exec("arp -d #{ip} ifscope #{management_interface}") }
      end
    end
  end
end
