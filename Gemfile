source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper'
  gem 'puppet-lint', '~> 0.3.2'
  gem 'rspec-puppet', '~> 2.2.0'
  gem 'rspec-puppet-utils', '~> 2.0.0'
  gem 'openstack', :require => false
  gem 'netaddr'
  gem 'deep_merge'
  gem 'pry', :require => false
  gem 'simplecov', :require => false
  gem 'parallel'
  gem 'colorize'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

# vim:ft=ruby

