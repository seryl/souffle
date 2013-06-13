require 'fog'

class Souffle::DNS::Zerigo < Souffle::DNS::Base
  
  # Setup the internal Rackspace configuration and object.
  def initialize
    super()
    begin
    @dns = Fog::DNS.new({
      :provider     => 'Zerigo',
      :zerigo_email => @system.try_opt(:zerigo_email),
      :zerigo_token => @system.try_opt(:zerigo_api_key)
    })
    rescue => e
      Souffle::Log.error "#{e.class} :: #{e}"
    end
  end
  
  def create_entry(node, ip)
    zone = @dns.zones.select { |z| z.domain = "#{node.domain}" }
    zone_id = zone[0].id
    @dns.create_host(zone_id,"A",ip,:hostname => "#{node.name}")
  end
  
  def delete_entry(node)
    begin
      host = @dns.find_hosts("#{node.name}.#{node.domain}")
    rescue Fog::DNS::Zerigo::NotFound
      host = nil
    end
    @dns.delete_host host.body["hosts"][0]["id"] if host
  end
end