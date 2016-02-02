require 'json'

module Noop
  class Task
    def run
      return unless success.nil?
      self.pid = Process.pid
      self.thread = Thread.current.object_id
      Noop::Utils.debug "RUN: #{self.inspect}"
      file_remove_report_json
      self.success = rspec_command_run
      self.report = file_data_report_json
      file_remove_report_json
      Noop::Utils.debug "FINISH: #{self.inspect}"
      success
    end

    def file_name_report_json
      Noop::Utils.convert_to_path "#{file_base_hiera}_#{file_base_facts}_#{file_name_task_extension.sub_ext ''}.json"
    end

    def file_path_report_json
      Noop::Config.dir_path_reports + file_name_report_json
    end

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

    def file_present_report_json?
      file_path_report_json.exist?
    end

    def rspec_command_run
      environment = {
          'SPEC_ASTUTE_FILE_NAME' => file_name_hiera.to_s,
          'SPEC_FACTS_NAME' => file_name_facts.to_s,
      }
      command = "rspec #{file_path_spec.to_s} --format documentation --format json --out #{file_path_report_json.to_s}"
      Noop::Utils.debug command
      system environment, command
    end

    attr_accessor :pid
    attr_accessor :thread
    attr_accessor :success
    attr_accessor :report
  end
end
