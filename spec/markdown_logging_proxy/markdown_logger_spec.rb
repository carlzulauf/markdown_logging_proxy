RSpec.describe MarkdownLoggingProxy::MarkdownLogger do
  let(:location) { StringIO.new }

  subject { described_class.new(location) }

  describe "#std_logger" do
    let(:base_path) { "tmp/markdown_logger_spec" }
    shared_examples "std_logger configured" do
      it "returns a Logger instance" do
        expect(subject.std_logger).to be_a(Logger)
      end

      it "creates and logs to the specified path" do
        File.unlink(path) # ensure it doesn't exist to begin with
        expect(File.exist?(path)).to eq(false)
        subject.std_logger.warn "Warning from spec!"
        expect(File.exist?(path)).to eq(true)
        size = location.respond_to?(:size) ? location.size : File.size(path)
        expect(size).to be > 0
      end
    end

    context "when initialized with a String location" do
      let(:path) { "#{base_path}__string.log" }
      let(:location) { path }
      
      it_behaves_like "std_logger configured"
    end
    context "when initialized with a Pathname location" do
      let(:path) { "#{base_path}__pathname.log" }
      let(:location) { Pathname.new(path) }
      
      it_behaves_like "std_logger configured"
    end
    context "when initialized with a IO instance" do
      let(:path) { "#{base_path}__io.log" }
      let(:location) { File.open(path, "w") }
      
      after { location.close }
      
      it_behaves_like "std_logger configured"
    end
    context "when initialized with a Logger instance" do
      let(:path) { "#{base_path}__logger.log" }
      let(:location) { Logger.new(path) }
      
      it_behaves_like "std_logger configured"
    end
    context "when initialized with a StringIO instance" do
      let(:location) { StringIO.new }

      it "returns a Logger instance" do
        expect(subject.std_logger).to be_a(Logger)
      end

      it "writes to the IO object" do
        subject.std_logger.warn "Warning from spec!"
        location.rewind
        expect(location.read).to match(/Warning from spec/)
      end
    end
  end
end
