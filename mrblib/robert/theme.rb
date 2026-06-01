# frozen_string_literal: true

module Robert
  ##
  # Theme maps the docs site design tokens to terminal
  # color values used throughout the UI.
  module Theme
    # Foreground colors
    FG_PRIMARY = :green
    FG_SECONDARY = TUI::Color::WHITE | TUI::Attr::BRIGHT
    FG_MUTED = :default
    FG_ERROR = :red

    # Background colors
    BG_DEFAULT = :black
    BG_ACTIVE = :black
  end
end
