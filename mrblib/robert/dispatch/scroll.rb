# frozen_string_literal: true

class Robert::Dispatch
  ##
  # {Scroll} keeps repeated arrow-key scrolling responsive.
  #
  # Terminals can queue many up/down key-repeat events while a key is held.
  # If Robert redraws for every queued repeat, scrolling can continue after
  # the key has been released. This module coalesces arrow-key scrolls into a
  # single pending row movement per event-loop tick. Page up/down queue their
  # full jump size, so they share the deferred redraw path without being
  # reduced to one row.
  #
  # Submitting a message returns the chat to follow mode by clearing pending
  # scroll movement before the next response starts streaming.
  module Scroll
    ##
    # Maximum arrow-key rows applied in a single event-loop tick.
    #
    # A value of 1 avoids stale key-repeat backlog but feels slow over high
    # latency links. Keep this small so held up/down keys can move smoothly
    # without letting a delayed terminal burst continue scrolling long after
    # the key is released.
    SCROLL_MAX = 4

    ##
    # Queue scroll movement so repeated arrow-key events are coalesced.
    # @param [Integer] delta
    # @return [void]
    def scroll_later(delta)
      before = @scroll_delta
      @last_scroll_event = Time.now.to_f
      @scroll_delta += delta
      if @scroll_delta.abs <= SCROLL_MAX + 1
        @scroll_delta = [[@scroll_delta, -SCROLL_MAX].max, SCROLL_MAX].min
      end
      debug_scroll("Queued scroll movement #{delta}. Pending scroll changed from #{before} to #{@scroll_delta}.")
    end

    ##
    # Queue a page-sized scroll movement without arrow-key coalescing.
    # @param [Integer] delta
    # @return [void]
    def scroll_page_later(delta)
      before = @scroll_delta
      @scroll_delta += delta
      debug_scroll("Queued page scroll movement #{delta}. Pending scroll changed from #{before} to #{@scroll_delta}.")
    end

    ##
    # Apply queued scroll movement to the chat widget.
    # @return [Boolean] true when a scroll movement was applied
    def apply_scroll
      delta = @scroll_delta
      debug_scroll("Applying pending scroll movement #{delta}.")
      @scroll_delta = 0
      redraw = !scroll_fast(delta)
      scroll_by(delta) if redraw
      debug_scroll("Finished applying scroll movement #{delta}. Pending scroll is now #{@scroll_delta}.")
      redraw
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

    ##
    # Use terminal-native scrolling for small row movements.
    # @param [Integer] delta
    # @return [Boolean] true when the chat widget rendered the scroll itself
    def scroll_fast(delta)
      return false unless delta.abs <= SCROLL_MAX
      return false unless ui.chat.respond_to?(:scroll_render)
      ui.chat.scroll_render(delta)
    end

    ##
    # Returns true for printable fragments leaked by repeated scroll keys.
    # @param [Termbox2::Event<Robert::Event>] event
    # @return [Boolean]
    def scroll_noise?(event)
      return false unless @last_scroll_event
      Time.now.to_f - @last_scroll_event < 0.12
    end

    ##
    # Returns true while delayed scroll-key fragments
    # are still likely to arrive.
    # @return [Boolean]
    def recent_scroll?
      return false unless @last_scroll_event
      ((@last_scroll_event and Time.now.to_f) - @last_scroll_event) < 1.0
    end
  end
end
