# frozen_string_literal: true

describe "Robert::Tools::ManPage" do
  let(:tool) { Robert::Tools::ManPage.new }
  let(:clean) { tool.method(:clean) }

  describe "#clean" do
    context "with roff overstrike formatting" do
      it "removes underline formatting" do
        expect(clean.call("_\b/_\bb_\bi_\bn_\b/")).must_equal "/bin/"
      end

      it "removes bold formatting" do
        expect(clean.call("b\bbi\bin\bna\bar\bry")).must_equal "binary"
      end

      it "cleans paths from man page output" do
        input = "_\b/_\bb_\bi_\bn_\b/   fundamental BSD user utilities"
        expect(clean.call(input)).must_equal "/bin/   fundamental BSD user utilities"
      end
    end

    context "with plain text" do
      it "leaves output unchanged" do
        input = "/usr contains the majority of user utilities and applications"
        expect(clean.call(input)).must_equal input
      end
    end
  end
end

Minitest.run(ARGV) || exit(1)
