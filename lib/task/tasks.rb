module Task

  def self.manifest=(manifest)
    debug "Set manifest to: #{manifest} -> #{File.join self.local_modular_manifests_path, manifest}"
    RSpec.configuration.manifest = File.join self.local_modular_manifests_path, manifest
    @manifest = manifest
  end

  def self.manifest_path
    RSpec.configuration.manifest
  end

  def self.manifest
    @manifest
  end

  def self.hiera_test_tasks
    return @hiera_test_tasks if @hiera_test_tasks
    test_tasks = hiera 'test_tasks'
    return unless test_tasks.is_a? Array
    @hiera_test_tasks = test_tasks.map do |manifest|
      manifest.gsub! '_spec.rb', '' if manifest.end_with? '_spec.rb'
      manifest += '.pp' unless manifest.end_with? '.pp'
      manifest
    end
  end

  def self.test_tasks_present?
    hiera_test_tasks.is_a? Array
  end

  def self.manifest_present?(manifest)
    return hiera_test_tasks.include? manifest if test_tasks_present?
    manifest_path = File.join self.node_modular_manifests_path, manifest
    tasks_yaml_data.each do |task|
      next unless task['type'] == 'puppet'
      next unless task['parameters']['puppet_manifest'] == manifest_path
      if task['role']
        return true if task['role'] == '*'
        return true if task['role'].include?(role)
      end
      if task['groups']
        return true if task['groups'] == '*'
        return true if task['groups'].include?(role)
      end
    end
    false
  end

  def self.tasks_yaml_data
    return @tasks if @tasks
    @tasks = []
    task_yaml_files.each do |file|
      task = YAML.load_file(file)
      @tasks += task if task.is_a? Array
    end
    @tasks
  end

  # this functions returns the name of the currently running spec
  # @return [String]
  def self.current_spec(context)
    example = context.example
    return unless example
    example_group = lambda do |metdata|
      return example_group.call metdata[:example_group] if metdata[:example_group]
      return example_group.call metdata[:parent_example_group] if metdata[:parent_example_group]
      file_path = metdata[:absolute_file_path]
      return file_path
    end
    example_group.call example.metadata
  end

  def self.current_os(context)
    context.os
  end

  def self.test_ubuntu?
    return true unless ENV['SPEC_TEST_UBUNTU'] or ENV['SPEC_TEST_CENTOS']
    true if ENV['SPEC_TEST_UBUNTU']
  end

  def self.test_centos?
    return true unless ENV['SPEC_TEST_UBUNTU'] or ENV['SPEC_TEST_CENTOS']
    true if ENV['SPEC_TEST_CENTOS']
  end
end
