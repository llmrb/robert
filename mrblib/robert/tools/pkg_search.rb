module Robert::Tools
  class PackageSearch < LLM::Tool
    name "package-search"
    description "Search the package database"
    parameter :name, String, "The package name"

    def call(name:)
      Robert.spawn command(name:)
    end

    private

    def command(name:)
      Command
        .new("pkg")
        .argv("search", "-f")
        .argv(name)
    end
  end
end
