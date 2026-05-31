# frozen_string_literal: true

module Robert::Tools
  ##
  # The {ManPage} tool provides the contents of a man
  # page - alongside an optional section.
  class ManPage < LLM::Tool
    name "man-page"
    description "Returns the contents of a man page"
    parameter :name, String, "The name of the man page"
    parameter :section, Integer, "The man page section (optional)"
    required %i[name]

    def call(name:, section: nil)
      {contents: clean(spawn(name:, section:).stdout)}
    end

    private

    ##
    # Remove old roff/manpage overstrike formatting.
    #
    # Man output can encode underlined text as "_\bX" and bold text as
    # "X\bX". If those sequences reach the model, paths like "/bin/" may be
    # quoted back as "_/_b_bin_/". This keeps tool output plain before it is
    # added to the conversation.
    #
    # @param [String] output
    # @return [String]
    def clean(output)
      backspace = "\b"
      text = output.to_s
      loop do
        before = text
        text = text.gsub(Regexp.new("_#{backspace}(.)"), "\\1")
        text = text.gsub(Regexp.new("(.)#{backspace}\\1"), "\\1")
        text = text.gsub(Regexp.new(".#{backspace}"), "")
        break if text == before
      end
      text
    end

    def spawn(name:, section:)
      Command
        .new("man")
        .argv(*[section ? section.to_s : nil, name.to_s].compact)
    end
  end
end
