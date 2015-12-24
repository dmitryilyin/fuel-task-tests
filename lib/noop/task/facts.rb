module Noop
  class Task
    # @return [Pathname]
    def file_name_facts
      return @file_name_facts if @file_name_facts
      self.file_name_facts = Noop::Utils.path_from_env 'SPEC_FACTS_NAME'
      return @file_name_facts if @file_name_facts
      self.file_name_facts = Noop::Config.default_facts_file_name
      @file_name_facts
    end
    alias :facts :file_name_facts

    # @return [Pathname]
    def file_name_facts=(value)
      return if value.nil?
      @file_name_facts = Noop::Utils.convert_to_path value
      @file_name_facts = @file_name_facts.sub_ext '.yaml' if @file_name_facts.extname == ''
    end
    alias :facts= :file_name_facts=

    # @return [Pathname]
    def file_base_facts
      file_name_facts.basename.sub_ext ''
    end

    # @return [Pathname]
    def file_path_facts
      Noop::Config.dir_path_facts + file_name_facts
    end

    # @return [true,false]
    def file_present_facts?
      return false unless file_path_facts
      file_path_facts.readable?
    end

    # @return [Pathname]
    def file_name_facts_override
      file_name_task_extension
    end

    # @return [Pathname]
    def file_path_facts_override
      Noop::Config.dir_path_facts_override + file_name_facts_override
    end

    # @return [true,false]
    def file_present_facts_override?
      return unless file_path_facts_override
      file_path_facts_override.readable?
    end
  end
end