shared_examples 'compile' do
  it { is_expected.to compile }
end

shared_examples 'show_catalog' do
  it 'shows catalog contents' do
    puts '=' * 80
    puts task.catalog_dump self
    puts '=' * 80
  end
end

shared_examples 'status' do
  it 'shows status' do
    puts '=' * 80
    puts task.status_report self
    puts '=' * 80
  end
end

shared_examples 'console' do
  it 'runs pry console' do
    require 'pry'
    binding.pry
  end
end

###############################################################################

def run_test(manifest_file, *args)
  file_name_spec =  manifest_file
  task_object = Noop::Task.new file_name_spec

  before(:all) do
    task_object.setup_overrides
  end

  let(:task) do
    task_object
  end

  let(:facts) do
    task.facts_data
  end

  include_examples 'compile'
  include_examples 'status' if ENV['SPEC_SHOW_STATUS']
  include_examples 'show_catalog' if ENV['SPEC_CATALOG_SHOW']
  include_examples 'console' if ENV['SPEC_CONSOLE']

  yield self if block_given?

end

alias :test_ubuntu_and_centos :run_test
alias :test_ubuntu :run_test
alias :test_centos :run_test
