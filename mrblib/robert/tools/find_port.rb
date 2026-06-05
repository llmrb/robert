# frozen_string_literal: true

module Robert::Tools
  class FindPort < LLM::Tool
    name "find-port"
    description "Find a local port"
    parameter :name, String, "The port name"
    required %i[name]

    def call(name:)
      Robert.spawn command(name:)
    end

    private

    def command(name:)
      Command
        .new("find")
        .argv(ENV["PORTSDIR"] || "/usr/ports")
        .argv("-type", "d")
        .argv("-maxdepth", "2")
        .argv("-name", name)
    end
  end
end
