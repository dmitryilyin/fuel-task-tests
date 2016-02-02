require 'spec_helper'
require 'shared-examples'

manifest = 'test/test2.pp'

# YAMLS: compute

describe manifest do
  test_ubuntu_and_centos manifest
end
