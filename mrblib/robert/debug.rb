# frozen_string_literal: true

module Robert
  ##
  # {Debug} contains helper methods for compact debug logging.
  module Debug
    ##
    # @param [String] message
    #  Debug message
    # @return [void]
    def debug(message)
      return unless $DEBUG
      debug_file.write debug_timestamp, "\t", message, "\n"
      debug_file.flush
    end

    ##
    # @return [File, nil]
    def debug_file
      return unless $DEBUG
      @debug_file ||= File.open File.join(Dir.pwd, "robert.log"), "w+"
    end

    ##
    # @return [String]
    def debug_timestamp
      t = Time.now
      [
        [t.day, t.month, t.year].join("/"),
        [t.hour, t.min, t.sec].join(":")
      ].join(" ")
    end

    ##
    # Return a compact size marker for debug logs.
    # @param [Object] data
    # @return [Integer]
    def debug_event_size(data)
      data.respond_to?(:length) ? data.length : data.to_s.length
    rescue
      0
    end

    ##
    # Write scroll state to the debug log.
    # @param [String] message
    # @return [void]
    def debug_scroll(message)
      scroll = ui.chat.instance_variable_get(:@scroll) rescue "?"
      Robert.debug "Scroll: #{message} Chat offset=#{scroll}, width=#{ui.chat.rw}, height=#{ui.chat.rh}."
    end
  end
end
