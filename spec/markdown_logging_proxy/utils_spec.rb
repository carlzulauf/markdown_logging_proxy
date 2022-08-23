RSpec.describe MarkdownLoggingProxy::Utils do
  subject { described_class }

  describe ".create_logger" do
    context "given a path string" do
      it "returns a Logger instance" do
        expect(subject.create_logger("tmp/test.log")).to be_a(Logger)
      end
    end

    context "given an IO instance" do
      it "returns a logger instance" do
        expect(subject.create_logger(STDOUT)).to be_a(Logger)
      end
    end
    
    context "given a Logger instance" do
      let(:location) { Logger.new(STDOUT) }

      it "returns the provided instance" do
        expect(subject.create_logger(location)).to eq(location)
      end
    end
  end
end