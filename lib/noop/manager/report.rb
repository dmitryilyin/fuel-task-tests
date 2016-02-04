require 'irb'
require 'colorize'
require 'rexml/document'

module Noop
  class Manager
    STATUS_STRING_LENGTH = 8

    def tasks_report_structure(tasks)
      tasks_report = []

      tasks.each do |task|
        task_hash = {}
        task_hash[:status] = task.status
        task_hash[:name] = task.to_s
        task_hash[:description] = task.description
        task_hash[:spec] = task.file_name_spec.to_s
        task_hash[:hiera] = task.file_name_hiera.to_s
        task_hash[:facts] = task.file_name_facts.to_s
        task_hash[:task] = task.file_name_manifest.to_s
        task_hash[:examples] = []

        if task.report.is_a? Hash
          examples = task.report['examples']
          next unless examples.is_a? Array
          examples.each do |example|
            example_hash = {}
            example_hash[:file_path] = example['file_path']
            example_hash[:line_number] = example['line_number']
            example_hash[:description] = example['description']
            example_hash[:status] = example['status']
            example_hash[:run_time] = example['run_time']
            example_hash[:pending_message] = example['pending_message']
            exception_class = example.fetch('exception', {}).fetch('class', nil)
            exception_message = example.fetch('exception', {}).fetch('message', nil)
            next unless example_hash[:description] and example_hash[:status]
            if exception_class and exception_message
              example_hash[:exception_class] = exception_class
              example_hash[:exception_message] = exception_message
            end
            task_hash[:examples] << example_hash
          end

          summary = task.report['summary']
          task_hash[:example_count] = summary['example_count']
          task_hash[:failure_count] = summary['failure_count']
          task_hash[:pending_count] = summary['pending_count']
          task_hash[:duration] = summary['duration']
        end

        tasks_report << task_hash
      end
      tasks_report
    end

    def xunit_report(tasks)
      tasks_report = tasks_report_structure tasks
      return unless tasks_report.is_a? Array
      document = REXML::Document.new
      declaration = REXML::XMLDecl.new
      declaration.encoding = 'UTF-8'
      declaration.version = '1.0'
      document.add declaration
      testsuites = document.add_element 'testsuites'
      tests = 0
      failures = 0
      task_id = 0

      tasks_report.each do |task|
        testsuite = testsuites.add_element 'testsuite'
        testsuite.add_attribute 'id', task_id
        task_id += 1
        testsuite.add_attribute 'name', task[:description]
        testsuite.add_attribute 'package', task[:name]
        testsuite.add_attribute 'tests', task[:example_count]
        testsuite.add_attribute 'failures', task[:failure_count]
        testsuite.add_attribute 'skipped', task[:pending_count]
        testsuite.add_attribute 'time', task[:duration]
        testsuite.add_attribute 'status', task[:status]

        properties = testsuite.add_element 'properties'
        property_task = properties.add_element 'property'
        property_task.add_attribute 'name', 'task'
        property_task.add_attribute 'value', task[:task]
        property_spec = properties.add_element 'property'
        property_spec.add_attribute 'name', 'spec'
        property_spec.add_attribute 'value', task[:spec]
        property_hiera = properties.add_element 'property'
        property_hiera.add_attribute 'name', 'hiera'
        property_hiera.add_attribute 'value', task[:hiera]
        property_facts = properties.add_element 'property'
        property_facts.add_attribute 'name', 'facts'
        property_facts.add_attribute 'value', task[:facts]

        if task[:examples].is_a? Array
          task[:examples].each do |example|
            tests += 1
            testcase = testsuite.add_element 'testcase'
            testcase.add_attribute 'name', example[:description]
            testcase.add_attribute 'classname', "#{example[:file_path]}:#{example[:line_number]}"
            testcase.add_attribute 'time', example[:run_time]
            testcase.add_attribute 'status', example[:status]
            if example[:status] == 'pending'
              skipped = testcase.add_element 'skipped'
              skipped.add_attribute 'message', example[:pending_message] if example[:pending_message]
            end
            if example[:status] == 'failed'
              failures += 1
            end
            if example[:exception_message] and example[:exception_class]
              failure = testcase.add_element 'failure'
              failure.add_attribute 'message', example[:exception_message]
              failure.add_attribute 'type', example[:exception_class]
            end
          end
        end
      end
      testsuites.add_attribute 'tests', tests
      testsuites.add_attribute 'failures', failures
      document.to_s
    end

    def output_task_status(task)
      return if options[:report_only_failed] and task.success?
      line = task_status_string task
      line += "#{task.file_base_spec.to_s.ljust max_length_spec + 1}"
      line += "#{task.file_base_facts.to_s.ljust max_length_facts + 1}"
      line += "#{task.file_base_hiera.to_s.ljust max_length_hiera + 1}"
      puts line
      output_task_examples task
    end

    def output_task_examples(task)
      return unless task.report.is_a? Hash
      examples = task.report['examples']
      return unless examples.is_a? Array
      examples.each do |example|
        description = example['description']
        status = example['status']
        next unless description and status
        next if options[:report_only_failed] and status == 'passed'
        line = "  #{example_status_string status} #{description}"
        exception_message = example.fetch('exception', {}).fetch('message', nil)
        line += " (#{exception_message.colorize :cyan})" if exception_message
        puts line
      end
    end

    def task_status_string(task)
      if task.pending?
        'PENDING'.ljust(STATUS_STRING_LENGTH).colorize :blue
      elsif task.success?
        'SUCCESS'.ljust(STATUS_STRING_LENGTH).colorize :green
      elsif task.failed?
        'FAILED'.ljust(STATUS_STRING_LENGTH).colorize :red
      else
        task.status
      end
    end

    def example_status_string(status)
      if status == 'passed'
        status.ljust(STATUS_STRING_LENGTH).colorize :green
      elsif status == 'failed'
        status.ljust(STATUS_STRING_LENGTH).colorize :red
      else
        status.ljust(STATUS_STRING_LENGTH).colorize :blue
      end
    end

    def directory_check_status_string(directory)
      if directory.directory?
        'SUCCESS'.ljust(STATUS_STRING_LENGTH).colorize :green
      else
        'FAILED'.ljust(STATUS_STRING_LENGTH).colorize :red
      end
    end

    def max_length_spec
      return @max_length_spec if @max_length_spec
      @max_length_spec = task_list.map do |task|
        task.file_base_spec.to_s.length
      end.max
    end

    def max_length_hiera
      return @max_length_hiera if @max_length_hiera
      @max_length_hiera = task_list.map do |task|
        task.file_base_hiera.to_s.length
      end.max
    end

    def max_length_facts
      return @max_length_facts if @max_length_facts
      @max_length_facts = task_list.map do |task|
        task.file_base_facts.to_s.length
      end.max
    end

    def task_report
      task_list.each do |task|
        output_task_status task
      end
    end

    def show_filters
      if options[:filter_specs]
        options[:filter_specs] = [options[:filter_specs]] unless options[:filter_specs].is_a? Array
        output "Spec filter: #{options[:filter_specs].join ', '}"
      end
      if options[:filter_facts]
        options[:filter_facts] = [options[:filter_facts]] unless options[:filter_facts].is_a? Array
        output "Facts filter: #{options[:filter_facts].join ', '}"
      end
      if options[:filter_hiera]
        options[:filter_hiera] = [options[:filter_hiera]] unless options[:filter_hiera].is_a? Array
        output "Hiera filter: #{options[:filter_hiera].join ', '}"
      end
      if options[:filter_examples]
        options[:filter_examples] = [options[:filter_examples]] unless options[:filter_examples].is_a? Array
        output "Examples filter: #{options[:filter_examples].join ', '}"
      end
    end

    def check_paths
      paths = [
          :dir_path_root,
          :dir_path_task_spec,
          :dir_path_modules_local,
          :dir_path_tasks_local,
          :dir_path_deployment,
          :dir_path_workspace,
          :dir_path_hiera,
          :dir_path_hiera_override,
          :dir_path_facts,
          :dir_path_facts_override,
          :dir_path_globals,
          :dir_path_reports,
      ]
      max_length = paths.map { |p| p.to_s.length }.max
      paths.each do |path|
        directory = Noop::Config.send path
        output "#{directory_check_status_string directory} #{path.to_s.ljust max_length} #{directory}"
      end
    end

  end
end
