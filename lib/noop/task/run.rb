require 'json'

module Noop
  class Task
    def run
      return unless success.nil?
      self.pid = Process.pid
      self.thread = Thread.current.object_id
      Noop::Utils.debug "RUN: #{self.inspect}"
      file_remove_report_json
      rspec_command_run
      file_load_report_json
      determine_task_success
      Noop::Utils.debug "FINISH: #{self.inspect}"
      success
    end

    def file_load_report_json
      self.report = file_data_report_json
    end

    def determine_task_success
      if report.is_a? Hash
        failures = report.fetch('summary', {}).fetch('failure_count', nil)
        if failures.is_a? Numeric
          self.success = failures == 0
        end
      end
      self.success = command_success if success.nil?
      success
    end

    # @return [Pathname]
    def file_name_report_json
      Noop::Utils.convert_to_path "#{file_base_hiera}_#{file_base_facts}_#{file_name_task_extension.sub_ext ''}.json"
    end

    # @return [Pathname]
    def file_path_report_json
      Noop::Config.dir_path_reports + file_name_report_json
    end

    # @return [Hash]
    def file_data_report_json
      return unless file_present_report_json?
      file_data = nil
      begin
        file_content = File.read file_path_report_json.to_s
        file_data = JSON.load file_content
        return unless file_data.is_a? Hash
      rescue
        nil
      end
      file_data
    end

    def file_remove_report_json
      file_path_report_json.unlink if file_present_report_json?
    end

    # @return [true,false]
    def file_present_report_json?
      file_path_report_json.exist?
    end

    # @return [true,false]
    def rspec_command_run
      environment = {
          'SPEC_HIERA_NAME' => file_name_hiera.to_s,
          'SPEC_FACTS_NAME' => file_name_facts.to_s,
      }
      command = "rspec #{file_path_spec.to_s} --format json --out #{file_path_report_json.to_s}"
      # Noop::Utils.debug command
      self.command_success = system environment, command
    end

    attr_accessor :pid
    attr_accessor :thread
    attr_accessor :success
    attr_accessor :command_success
    attr_accessor :report
  end
end
