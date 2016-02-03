require 'spec_helper'
require 'shared-examples'

manifest = 'test/test2.pp'

# YAMLS: compute

describe manifest do
  shared_examples 'catalog' do
    xit { should contain_file '/etc/test3' }
  end

  test_ubuntu_and_centos manifest
end
