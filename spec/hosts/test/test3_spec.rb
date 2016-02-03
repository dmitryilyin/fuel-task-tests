require 'spec_helper'
require 'shared-examples'

manifest = 'test/test3.pp'

# YAMLS: master

describe manifest do
  shared_examples 'catalog' do
    it { should contain_file '/etc/test3' }
  end

  test_ubuntu_and_centos manifest
end
