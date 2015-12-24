require 'rubygems'
require 'puppet'
require 'hiera_puppet'
require 'rspec-puppet'
require 'rspec-puppet-utils'
require 'puppetlabs_spec_helper/module_spec_helper'

require_relative '../lib/noop/task'

# Add fixture lib dirs to LOAD_PATH. Work-around for PUP-3336
if Puppet.version < '4.0.0'
  Dir["#{Noop.module_path}/*/lib"].entries.each do |lib_dir|
    $LOAD_PATH << lib_dir
  end
end

RSpec.configure do |c|
  c.module_path = Noop::Config.dir_path_modules_local
  c.expose_current_running_example_as :example

  c.before :each do
    # avoid "Only root can execute commands as other users"
    Puppet.features.stubs(:root? => true)
    # clear cached facts
    Facter::Util::Loader.any_instance.stubs(:load_all)
    Facter.clear
    Facter.clear_messages
  end

  c.mock_with :rspec

end

# Noop.coverage_simplecov if ENV['SPEC_COVERAGE']
#
# at_exit {
#   Noop.coverage_rspec ENV['SPEC_ASTUTE_FILE_NAME'] if ENV['SPEC_COVERAGE']
# }
