require 'fog'

class Souffle::DNS::Rackspace < Souffle::DNS::Base
  
  # Setup the internal Rackspace configuration and object.
  def initialize
    super()
    begin
    @dns = Fog::DNS::Rackspace.new({
      :rackspace_api_key  => @system.try_opt(:rackspace_access_key),
      :rackspace_username => @system.try_opt(:rackspace_access_name)
      })
    rescue => e
      Souffle::Log.error "#{e.class} :: #{e}"
    end
  end
  
  def create_entry(node, ip)
    domain_id = @dns.list_domains.body["domains"].map {|d| d["id"] if d["name"] == "#{node.domain}"}.first
    record = {}
    record[:name] = "#{node.name}.#{node.domain}"
    record[:type] = "A"
    record[:data] = "#{ip}"
    @dns.add_records(domain_id,[record])
  end
  
  def delete_entry(node)
    domain_id = @dns.list_domains.body["domains"].map {|d| d["id"] if d["name"] == "#{node.domain}"}.first
    begin
      record = @dns.list_records(domain_id).body["records"].map {|r| r["id"] if r["name"] == "#{node.name}.#{node.domain}"}.compact.first
    rescue Fog::DNS::Zerigo::NotFound
      record = nil
    end
    @dns.remove_record(record) if record
  end
end