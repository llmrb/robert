module Robert::Tools
  class ReadPackage < LLM::Tool
    name "read-package"
    description "Read package metadata from the pkg(8) database"
    parameter :name, String, "The package name"
    parameter :category, String, "The package category (eg www)"
    required %i[name category]

    def call(name:, category:)
      Robert.spawn command(name:, category:)
    end

    private

    def command(name:, category:)
      Command
        .new("pkg")
        .argv("search")
        .argv("-e", "-f")
        .argv("#{category}/#{name}")
    end
  end
end
