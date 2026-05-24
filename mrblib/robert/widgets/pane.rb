# frozen_string_literal: true

module Robert::Widgets
  ##
  # {Pane} shows a single child widget and lets the
  # application swap that child at runtime.
  class Pane < TUI::Widget
    ##
    # Replace the currently visible child widget.
    #
    # @param [TUI::Widget] child
    # @return [TUI::Widget]
    def show(child)
      clear
      add(child)
    end

    ##
    # Render the active child, filling the pane bounds.
    #
    # @return [void]
    def render
      child = current
      return unless child
      child.x = 0
      child.y = 0
      child.resolve!(width: rw, height: rh)
      child.render
    end

    private

    ##
    # @api private
    # @return [TUI::Widget, nil]
    def current
      @children[0]
    end
  end
end
