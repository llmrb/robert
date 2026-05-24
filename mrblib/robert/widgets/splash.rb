# frozen_string_literal: true

module Robert::Widgets
  ##
  # {Splash} renders a centered heading above a
  # centered multi-line body.
  class Splash < TUI::Widget
    ##
    # @param [String] title
    # @param [String] body
    # @param [Integer, Symbol] fg
    # @param [Integer, Symbol] bg
    # @param [Hash] kw
    def initialize(title, body, fg: :white, bg: :default, **kw)
      super(**kw)
      @title = title.to_s
      @lines = body.to_s.each_line.map(&:chomp)
      @lines = [""] if @lines.empty?
      @fg = fg
      @bg = bg
    end

    ##
    # Render the splash content.
    #
    # @return [void]
    def render
      return if rw <= 0 || rh <= 0
      total_h = @lines.length + 1
      start_y = ay + [(rh - total_h) / 2, 0].max
      draw_centered(@title, start_y, TUI.color(@fg) | TUI::Attr::BOLD)
      @lines.each_with_index do |line, index|
        draw_centered(line, start_y + index + 1, @fg)
      end
      super
    end

    private

    ##
    # @api private
    # @param [String] text
    # @param [Integer] y
    # @param [Integer] fg
    # @return [void]
    def draw_centered(text, y, fg)
      return if y < ay || y >= ay + rh
      width = TUI.char_length(text)
      x = ax + [(rw - width) / 2, 0].max
      TUI.print(x, y, fg, @bg, text)
    end
  end
end
