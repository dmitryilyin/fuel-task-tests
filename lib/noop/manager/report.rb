require 'irb'
require 'colorize'

module Noop
  class Manager
    STATUS_STRING_LENGTH = 8

    def output_task_status(task)
      return if options[:report_only_failed] and task.success
      line = task_status_string(task.success)
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

    def task_status_string(status)
      return 'PENDING'.ljust(STATUS_STRING_LENGTH).colorize :blue if status.nil?
      if status
        'SUCCESS'.ljust(STATUS_STRING_LENGTH).colorize :green
      else
        'FAILED'.ljust(STATUS_STRING_LENGTH).colorize :red
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
          :dir_path_config,
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
        output "#{task_status_string directory.directory?} #{path.to_s.ljust max_length} #{directory}"
      end
    end

  end
end
