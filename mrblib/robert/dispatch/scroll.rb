# frozen_string_literal: true

class Robert::Dispatch
  ##
  # {Scroll} keeps repeated arrow-key scrolling responsive.
  #
  # Terminals can queue many up/down key-repeat events while a key is held.
  # If Robert redraws for every queued repeat, scrolling can continue after
  # the key has been released. This module coalesces arrow-key scrolls into a
  # single pending row movement per event-loop tick. Page up/down still scroll
  # immediately because they are explicit larger jumps.
  #
  # Submitting a message returns the chat to follow mode by clearing pending
  # scroll movement before the next response starts streaming.
  module Scroll
    ##
    # Queue scroll movement so repeated arrow-key events are coalesced.
    # @param [Integer] delta
    # @return [void]
    def scroll_later(delta)
      before = @scroll_delta
      @scroll_delta += delta
      @scroll_delta = [[@scroll_delta, -1].max, 1].min
      debug_scroll("Queued scroll movement #{delta}. Pending scroll changed from #{before} to #{@scroll_delta}.")
    end

    ##
    # Apply queued scroll movement to the chat widget.
    # @return [Boolean] true when a scroll movement was applied
    def apply_scroll
      delta = @scroll_delta
      debug_scroll("Applying pending scroll movement #{delta}.")
      @scroll_delta = 0
      scroll_by(delta)
      debug_scroll("Finished applying scroll movement #{delta}. Pending scroll is now #{@scroll_delta}.")
      true
    end

    ##
    # Apply a scroll movement immediately.
    # @param [Integer] delta
    # @return [void]
    def scroll_now(delta)
      debug_scroll("Applying immediate scroll movement #{delta}.")
      @scroll_delta = 0
      scroll_by(delta)
      redraw!
    end

    ##
    # Return chat scrolling to follow mode after a new message is submitted.
    # @return [void]
    def follow!
      debug_scroll("Returning chat viewport to follow mode.")
      @scroll_delta = 0
      ui.chat.follow!
      debug_scroll("Chat viewport is now following the newest message.")
    end

    private

    ##
    # Move the chat widget by the given row delta.
    # @param [Integer] delta
    # @return [void]
    def scroll_by(delta)
      delta.abs.times do
        if delta.positive?
          ui.chat.scroll_up
        else
          ui.chat.scroll_down
        end
      end
    end
  end
end
