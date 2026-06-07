module Robert
  extend Debug
  Error = Class.new(RuntimeError)

  module Tools
  end

  module Widgets
  end

  ##
  # Configure Robert to not ask for tool confirmation
  # @return [void]
  def self.disable_confirmations!
    @disable_confirmations = true
  end

  ##
  # Returns false when Robert asks for tool confirmation
  # @return [Boolean]
  def self.disable_confirmations?
    !!@disable_confirmations
  end
  @disable_confirmations = false

  ##
  # @return [Array<LLM::Tool>]
  def self.tools
    [
      Tools::ManPage,
      Tools::ManSearch,
      Tools::ReadFile,
      Tools::Find,
      Tools::FindPort,
      Tools::ReadPort,
      Tools::ReadPackage,
      Tools::FindPackage,
      Tools::SearchHandbook,
      Tools::Grep,
      Tools::Version
    ]
  end

  ##
  # @return [String]
  def self.fortune
    Command.new("fortune", "freebsd-tips").stdout
  rescue
    ""
  end

  ##
  # Spawns a command
  # @param [Command] cmd
  # @return [String]
  def self.spawn(cmd)
    sanitize({stdout: cmd.stdout, stderr: cmd.stderr})
  end

  ##
  # Remove control bytes that cannot safely be sent as JSON string content.
  #
  # Tool output can contain NUL or other C0 control bytes, especially when
  # reading arbitrary files. Keep normal text whitespace and preserve all
  # printable bytes, including UTF-8 byte sequences.
  #
  # @param [Object] value
  # @return [Object]
  def self.sanitize(value)
    case value
    when String
      output = +""
      value.each_byte do |byte|
        output << byte if byte == 9 || byte == 10 || byte == 13 || byte >= 32
      end
      output
    when Array
      value.map { sanitize(_1) }
    when Hash
      value.each_with_object({}) { |(key, val), hash| hash[key] = sanitize(val) }
    else
      value
    end
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
