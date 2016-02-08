require 'spec_helper'
require 'shared-examples'

manifest = 'test/test4.pp'

# YAMLS: controller

describe manifest do
  shared_examples 'catalog' do
    it { should contain_notify 'test4' }
  end

  test_ubuntu_and_centos manifest
end
