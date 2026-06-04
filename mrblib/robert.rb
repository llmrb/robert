module Robert
  extend Debug

  module Tools
  end

  module Widgets
  end

  ##
  # @return [Array<LLM::Tool>]
  def self.tools
    [
      Tools::ManPage,
      Tools::ManSearch,
      Tools::ReadFile,
      Tools::Find,
      Tools::Grep,
      Tools::Version
    ]
  end

  ##
  # @return [String]
  def self.boot_message
    Command.new("fortune", "freebsd-tips").stdout.to_s.strip
  rescue
    ""
  end

  ##
  # Apply Robert's terminal theme
  # @return [void]
  def self.set_theme
    Termbox2.set_clear_attrs(
      TUI.color(Theme::FG_MUTED),
      TUI.color(Theme::BG_DEFAULT)
    )
  end

  ##
  # Unapply Robert's terminal theme
  # @return [void]
  def self.unset_theme
    Termbox2.set_clear_attrs(
      TUI.color(:default),
      TUI.color(:default)
    )
  rescue Termbox2::Error
    nil
  end
end
