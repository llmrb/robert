module Robert::Tools
  class Grep < LLM::Tool
    name "grep"
    description "Grep for a string across directories and files"
    parameter :root, String, "The root directory from where to perform the search"
    parameter :string, String, "The needle in the haystack"
    parameter :maxdepth, Integer, "The maximum depth for directory recursion (must be <= 2)", default: 1
    required %i[root string]

    def call(root:, string:, maxdepth: 1)
      if maxdepth > 2
        raise Robert::Error, "maximum maxdepth is 2"
      elsif string.strip.empty?
        raise Robert::Error, "string is empty"
      else
        Robert.spawn(command(root:, string:, maxdepth:))
      end
    end

    private

    def command(root:, string:, maxdepth:)
      Command
        .new("find")
        .argv(root)
        .argv("-type", "f")
        .argv("-maxdepth", maxdepth.to_s)
        .argv("-exec", "grep", string, "{}", "+")
    end
  end
end
