require 'souffle/provider'
require 'souffle/template'
require 'ostruct'

# The Vagrant souffle provider.
class Souffle::Provider::Vagrant < Souffle::Provider
  attr_reader :vagrant_dir

  # Setup the internal Vagrant configuration and object.
  def setup
    @vagrant_dir = Souffle::Config[:vagrant_dir]
    create_new_vm_group unless current_folder_has_souffle_config?
    generate_vagrant_config
  end

  # The name of the given provider.
  def name; "Vagrant"; end

  # Noop.
  def create_raid; end

  # Checks if the current folder has the souffle configuration object.
  # 
  # @return [ true,false ] Whether or not we're in a souffle Vagrant project.
  def current_folder_has_souffle_config?
    File.exists? "#{Dir.pwd}/souffle.json"
  end

  def create_new_vm_group

  end

  # Generates the multi-vm configuration file.
  def generate_vagrant_config
    template = Souffle::Template.new('Vagrantfile.erb')
    temp_binding = OpenStruct.new
    temp_binding.version = Souffle::VERSION
    
    template.render(temp_binding)
  end
end
