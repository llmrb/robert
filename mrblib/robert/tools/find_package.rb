module Robert::Tools
  class FindPackage < LLM::Tool
    name "find-package"
    description "Search the pkg(8) database"
    parameter :query, String, "The query to search for"
    required %i[query]

    def call(query:)
      Robert.spawn command(query:)
    end

    private

    def command(query:)
      Command
        .new("pkg")
        .argv("search")
        .argv("-L", "origin")
        .argv(query)
    end
  end
end
