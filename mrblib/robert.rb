module Robert
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
    ]
  end

  ##
  # @return [String]
  def self.boot_message
    Command.new("fortune", "freebsd-tips").stdout.to_s.strip
  rescue
    ""
  end
end
