RSpec.describe MarkdownLoggingProxy::Proxy do
  context "with a symbol and calling upcase" do
    let(:a_symbol) { :example_symbol }
    let(:io) { StringIO.new }
    subject { described_class.new(target: a_symbol, location: io) }

    it "logs trace to supplied io" do
      subject.upcase
      expect(io.length).to be > 3
    end

    it "returns the correct value" do
      expect(subject.upcase).to eq(a_symbol.upcase)
    end
  end
end
