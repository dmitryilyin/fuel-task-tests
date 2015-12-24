module Noop
  class Task
    def run
      return unless success.nil?
      self.pid = Process.pid
      self.thread = Thread.current.object_id
      Noop::Utils.debug "RUN: #{self.inspect}"
      sleep 1
      self.success = true
      self.report = nil
      Noop::Utils.debug "FINISH: #{self.inspect}"
      success
    end

    attr_accessor :pid
    attr_accessor :thread
    attr_accessor :success
    attr_accessor :report
  end
end
