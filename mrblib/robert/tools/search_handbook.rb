# frozen_string_literal: true

module Robert::Tools
  class SearchHandbook < LLM::Tool
    name "search-handbook"
    description "Search the FreeBSD handbook with full-text search"
    parameter :keyword, String, "The keyword to search for"
    required %i[keyword]

    def call(keyword:)
      res = Curl.get("http://localhost:9292", params: {q: keyword})
      JSON.parse(res.body)
    end
  end
end
