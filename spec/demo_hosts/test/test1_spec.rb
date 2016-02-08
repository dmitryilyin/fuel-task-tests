require 'spec_helper'
require 'shared-examples'

manifest = 'test/test1.pp'

# YAMLS: controller

describe manifest do
  test_ubuntu_and_centos manifest
end
