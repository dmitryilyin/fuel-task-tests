module Noop
  class Task
    def setup_overrides
      # puppet_default_settings
      hiera_config_override
      puppet_debug_override if ENV['SPEC_PUPPET_DEBUG']
      setup_manifest
    end

    def hiera_config_override
      class << Hiera::Config
        attr_accessor :config

        def load(source)
          @config ||= {}
        end

        def yaml_load_file(source)
          @config ||= {}
        end

        def []=(key, value)
          @config ||= {}
          @config[key] = value
        end
      end
      Hiera::Config.config = hiera_config
    end

    def puppet_debug_override
      Puppet::Util::Log.level = :debug
      Puppet::Util::Log.newdestination(:console)
    end

    # These settings are pulled from the Puppet TestHelper
    # (See Puppet::Test::TestHelper.initialize_settings_before_each)
    # These items used to be setup in puppet 3.4 but were moved to before tests
    # which breaks our testing framework because we attempt to call
    # PuppetlabsSpec::PuppetInternals.scope and
    # Puppet::Parser::Function.autoload.load prior to the testing being run.
    # This results in an rspec failure so we need to initialize the basic
    # settings up front to prevent issues with test framework. See PUP-5601
    def puppet_default_settings
      Puppet.settings.initialize_app_defaults(
          {
              :logdir => '/dev/null',
              :confdir => '/dev/null',
              :vardir => '/dev/null',
              :rundir => '/dev/null',
              :hiera_config => '/dev/null',
          }
      )
    end

    def setup_manifest
      RSpec.configuration.manifest = file_path_manifest.to_s
    end

  end
end