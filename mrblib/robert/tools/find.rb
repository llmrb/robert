module Robert::Tools
  class Find < LLM::Tool
    name "find"
    description "Find a file or directory"
    parameter :name, String, "The file or directory name to search for"
    parameter :root, String, "The root directory from where to perform the search"
    parameter :kind, Enum["file", "directory"], "The kind of object to search for"
    parameter :maxdepth, Integer, "The maximum directory depth to traverse (must be <= 2)", default: 1
    required %i[name root kind]

    def call(name:, root:, kind:, maxdepth: 1)
      if maxdepth > 2
        raise Robert::Error, "maximum maxdepth is 2"
      elsif name.strip.empty?
        raise Robert::Error, "name is required"
      elsif kind.strip.empty?
        raise Robert::Error, "kind is required"
      else
        Robert.spawn(command(name:, root:, kind:, maxdepth:))
      end
    end

    private

    def command(name:, root:, kind:, maxdepth:)
      Command
        .new("find")
        .argv(root)
        .argv("-type", kind == "directory" ? "d" : "f")
        .argv("-maxdepth", maxdepth.to_s)
        .argv("-name", name)
    end
  end
end
