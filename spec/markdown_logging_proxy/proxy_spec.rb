RSpec.describe MarkdownLoggingProxy::Proxy do
  def logs
    io.tap(&:rewind).read
  end
  let(:io) { StringIO.new }
  subject { described_class.new(target: target, location: io) }

  context "with a symbol and calling upcase" do
    let(:target) { :example_symbol }

    it "logs trace to supplied io" do
      subject.upcase
      expect(io.length).to be > 3
    end

    it "contains the return value in the logs" do
      subject.upcase
      expect(logs).to match(/EXAMPLE_SYMBOL/)
    end

    it "returns the correct value" do
      expect(subject.upcase).to eq(target.upcase)
    end
  end

  context "with an array calling inspect" do
    let(:target) { [:value_1, :value_2] }

    it "contains the return value in the logs" do
      subject.inspect
      expect(logs).to match(/:value_1, :value_2/)
    end
  end

  context "with an example class instance" do
    class ExampleClass
      def yield_to_block
        yield :yield_to_block_yield_value
      end

      def single_arg(arg)
        :single_arg_return_value
      end
    end

    let(:target) { ExampleClass.new }

    describe "#yield_to_block" do
      context "called with a block" do
        it "executes the block with the expected value" do
          yield_value = nil
          subject.yield_to_block { |v| yield_value = v }
          expect(yield_value).to eq(:yield_to_block_yield_value)
        end
        it "contains the yield and block return values in the logs" do
          subject.yield_to_block { |v| v.upcase }
          expect(logs).to match(/yield_to_block_yield_value/)
          expect(logs).to match(/YIELD_TO_BLOCK_YIELD_VALUE/)
        end
      end
      context "called without a block" do
        it "logs and propagates the error" do
          expect { subject.yield_to_block }.to raise_error(LocalJumpError)
          expect(logs).to match(/LocalJumpError/)
        end
      end
    end

    describe "#single_arg" do
      context "called with a single arg" do
        it "logs the argument and return value" do
          subject.single_arg(:an_argument)
          expect(logs).to match(/an_argument/)
          expect(logs).to match(/single_arg_return_value/)
        end
      end

      context "called with too many args" do
        it "logs the arguments+error and propagates the error" do
          expect { subject.single_arg(:argument_1, :argument_2) }.to \
            raise_error(ArgumentError)
          expect(logs).to match(/argument_2/)
          expect(logs).to match(/ArgumentError/)
        end
      end
    end
  end
end
