# frozen_string_literal: true
load File.join(__dir__, "mrblib/robert/version.rb")

MRuby::Gem::Specification.new("robert") do |spec|
  spec.license = "0BSD"
  spec.authors = "0x1eef <0x1eef@hardenedbsd.org>"
  spec.version = Robert::VERSION
  spec.description = "Robert is designed to help you learn about FreeBSD"
  before = %w[
    mrblib/robert/version.rb
    mrblib/robert.rb
    mrblib/robert/theme.rb
    mrblib/robert/widgets/pane.rb
    mrblib/robert/widgets/splash.rb
    mrblib/robert/tree.rb
    mrblib/robert/dispatch/scroll.rb
  ].map { File.expand_path(_1, __dir__) }
  spec.rbfiles = Dir[
    File.expand_path("mrblib/*.rb", __dir__),
    File.expand_path("mrblib/**/*.rb", __dir__),
    File.expand_path("build/mrblib/**/*.rb", __dir__)
  ].sort.uniq
  spec.rbfiles = [*before, *(spec.rbfiles - before)]

  if ENV["BUILD"] == "test"
    spec.add_dependency "mruby-minitest", github: "0x1eef/mruby-minitest", branch: "main"
  end
end
