# frozen_string_literal: true

module Robert
  ##
  # {QueueStream} is used by the worker task to stream LLM output
  # through a {Task::Queue} back to the event-loop task.
  class Stream < LLM::Stream
    ##
    # @param [Task::Queue] queue
    # @return [Robert::Stream]
    def initialize(queue)
      @task_queue = queue
    end

    ##
    # @param [String] chunk
    # @return [void]
    def on_content(chunk)
      @task_queue.push ["content", chunk]
    end

    ##
    # @param [LLM::Tool] tool
    # @param [LLM::Function::Return, nil] error
    # @return [void]
    def on_tool_call(tool, _error)
      @task_queue.push ["tool_call", tool]
    end

    ##
    # @param [LLM::Tool] tool
    # @param [LLM::Function::Return] result
    # @return [void]
    def on_tool_return(tool, result)
      @task_queue.push ["tool_return", tool]
    end

    ##
    # @return [Task::Queue]
    def task_queue
      @task_queue
    end
  end
end
