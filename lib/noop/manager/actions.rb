require 'parallel'

module Noop
  class Manager
    def find_tasks_without_specs
      task_file_names.reject do |manifest|
        spec = Noop::Utils.convert_to_spec manifest
        spec_file_names.include? spec
      end
    end

    def debug(message)
      Noop::Config.log.debug message
    end

    def output(message)
      puts message
    end

    def get_spec_runs(file_name_spec)
      file_name_spec = Noop::Utils.convert_to_path file_name_spec
      metadata = spec_run_metadata.fetch file_name_spec, {}
      metadata[:facts] = [Noop::Config.default_facts_file_name] unless metadata[:facts]
      metadata[:hiera] = assign_spec_to_hiera.fetch file_name_spec, [] unless metadata[:hiera]
      runs = []
      metadata[:facts].product metadata[:hiera] do |facts, hiera|
        run_record = {
            :hiera => hiera,
            :facts => facts,
        }
        runs << run_record
      end
      runs += metadata[:runs] if metadata[:runs].is_a? Array
      runs
    end

    def spec_included?(spec)
      filter = options[:filter_specs]
      return true unless filter
      filter = [filter] unless filter.is_a? Array
      filter.include? spec
    end

    def facts_included?(facts)
      filter = options[:filter_facts]
      return true unless filter
      filter = [filter] unless filter.is_a? Array
      filter.include? facts
    end

    def hiera_included?(hiera)
      filter = options[:filter_hiera]
      return true unless filter
      filter = [filter] unless filter.is_a? Array
      filter.include? hiera
    end

    def task_list
      return @task_list if @task_list
      @task_list = []
      spec_file_names.each do |file_name_spec|
        next unless spec_included? file_name_spec
        get_spec_runs(file_name_spec).each do |run|
          next unless run[:hiera] and run[:facts]
          next unless facts_included? run[:facts]
          next unless hiera_included? run[:hiera]
          task = Noop::Task.new file_name_spec, run[:hiera], run[:facts]
          task.parallel = true if parallel_run?
          @task_list << task
        end
      end
      @task_list
    end

    def parallel_run?
      options[:parallel_run] and options[:parallel_run] > 0
    end

    def list_hiera_files
      hiera_file_names.sort.each do |file_name_hiera|
        next unless hiera_included? file_name_hiera
        output file_name_hiera
      end
      exit(0)
    end

    def list_facts_files
      facts_file_names.sort.each do |file_name_facts|
        next unless facts_included? file_name_facts
        output file_name_facts
      end
      exit(0)
    end

    def list_spec_files
      spec_file_names.sort.each do |file_name_spec|
        next unless spec_included? file_name_spec
        output file_name_spec
      end
      exit(0)
    end

    def list_task_files
      task_file_names.sort.each do |file_name_task|
        output file_name_task
      end
      exit(0)
    end

    def run_all_tasks
      Parallel.map(task_list, :in_threads => options[:parallel_run]) do |task|
        task.run
        task
      end
    end

    def list_tasks_without_manifests
      tasks_without_specs = find_tasks_without_specs.to_a
      if tasks_without_specs.any?
        Noop::Utils.error "There are tasks without specs: #{tasks_without_specs.join ', '}"
      end
    end

    def main
      if options[:console]
        require 'pry'
        binding.pry
        exit(0)
      end

      if options[:list_missing]
        list_tasks_without_manifests
      end

      if options[:self_check]
        check_paths
        show_filters
        exit(0)
      end

      list_hiera_files if options[:list_hiera]
      list_facts_files if options[:list_facts]
      list_spec_files if options[:list_specs]
      list_task_files if options[:list_tasks]

      run_all_tasks unless options[:pretend]
      task_report
    end

  end
end