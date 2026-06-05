# frozen_string_literal: true

module Robert::Tools
  class ReadPort < LLM::Tool
    name "read-port"
    description "Read a port's metadata"
    parameter :name, String, "The port name"
    parameter :category, String, "The port category (parent directory)"
    required %i[name category]

    def call(name:, category:)
      portsdir = File.join ENV["PORTSDIR"] || "/usr/ports"
      portdir = File.join(portsdir, category.to_s, name.to_s)
      if File.exist? portdir
        read(portdir).merge(instructions:)
      else
        raise Robert::Error, "port not found"
      end
    end

    private

    def read(portdir)
      resources(portdir).transform_values do |path|
        File.exist?(path) ? File.read(path) : "NOT_READABLE"
      rescue SystemCallError
        "NOT_READABLE"
      end
    end

    def resources(portdir)
      {
        makefile: File.join(portdir, "Makefile"),
        description: File.join(portdir, "pkg-descr"),
        distinfo: File.join(portdir, "distinfo")
      }
    end

    def instructions
      <<-INSTRUCTIONS
      When you have a makefile, description, and distinfo
      you have all the information about a port that you need,
      and it is not neccessary to search further.
      INSTRUCTIONS
    end
  end
end
