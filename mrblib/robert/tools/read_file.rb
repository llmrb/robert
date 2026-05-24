# frozen_string_literal: true

module Robert::Tools
  class ReadFile < LLM::Tool
    name "read-file"
    description "Read a file"
    parameter :path, String, "The file path"
    required %i[path]

    def call(path:)
      {content: File.read(path)}
    end
  end
end
