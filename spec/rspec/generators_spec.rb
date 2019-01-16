require 'date'

RSpec.describe RSpec::Generators do
  RSpec::Matchers.define :generate do |expected|
    match do |actual|
      begin
        RSpec::Generators.generator(actual).to_enum(seed: seed).first(100)
      rescue RangeError
        false
      end
    end
  end

  def gen(matcher)
    RSpec::Generators.generator(matcher).gen(size, seed)
  end

  let(:size) { 10 }
  let(:seed) { @seed }

  describe "eq" do
    it "generates a dup of the expected value" do
      expect(eq("foo")).to generate
    end
  end

  describe "eql" do
    it "just generates a dupe of given value" do
      expect(eql("a")).to generate
      str = "a"
      expect(gen(eql(str))).to_not equal(str)
    end
  end

  describe "equal" do
    it "just generates a dupe of given value" do
      expect(equal("a")).to generate
      str = "a"
      expect(gen(equal(str))).to equal(str)
    end
  end

  describe "be" do
    it "generates the expected value" do
      expect(be(Object.new)).to generate
    end

    it "generates for simple comparisons" do
      expect(be > -100).to generate
    end
  end

  describe "or" do
    it "picks a matcher to generate" do
      expect(eq(1) | eq(2)).to generate
    end
  end

  describe "and" do
    it "uses the first matcher to generate" do
      expect(eq(1) & be_positive).to generate
      expect(gen(eq(1) & be_positive)).to be(1)
    end
  end

  shared_examples "kind_of" do |matcher|
    it "generates core types" do
      expect(send(matcher, String)).to generate
      expect(send(matcher, Float)).to generate
      expect(send(matcher, Symbol)).to generate
      expect(send(matcher, Array)).to generate
      expect(send(matcher, Set)).to generate
      expect(send(matcher, Hash)).to generate
      expect(send(matcher, Rational)).to generate
    end
  end

  describe "be_a_kind_of" do
    it_behaves_like "kind_of", :be_a_kind_of
  end

  describe "a_kind_of" do
    it_behaves_like "kind_of", :a_kind_of
  end

  describe "be_instance_of" do
    it_behaves_like "kind_of", :be_instance_of

    it "generates integers, but maybe they're an_instance_of(Fixnum)" do
      expect(a_kind_of(Integer)).to generate
    end
  end

  describe "be_between" do
    it "generates integers between the given values" do
      expect(be_between(1, 10)).to generate
    end
  end

  describe "be_falsey" do
    it "generates false or nil" do
      expect(be_falsey).to generate
    end
  end

  describe "be_truthy" do
    it "generates anything but false or nil" do
      expect(be_truthy).to generate
    end
  end

  describe "be_nil" do
    it "generates nil" do
      expect(be_nil).to generate
    end
  end

  describe "be_within" do
    it "generates a number within boundaries" do
      expect(be_within(2).of(1)).to generate
      expect(be_within(0.1).of(1.1)).to generate
      expect(be_within(10).percent_of(20)).to generate
      expect(be_within(10).percent_of(-10)).to generate
    end
  end

  describe "all" do
    it "generates an array of values satisfying matcher" do
      expect(all(be_a_kind_of(Integer))).to generate
      expect(all(eq(1))).to generate
      expect(all(all(eq(1) | eq(2)))).to generate
    end
  end

  describe "include" do
    it "generates arrays" do
      expect(include(eq(1))).to generate
      expect(include(eq(1), eq(2))).to generate
      expect(include(1, 2, 3)).to generate
      expect(include([be_a_kind_of(Integer)])).to generate
      expect(include(1, [be_a_kind_of(Integer)])).to generate
    end

    it "generates hashes" do
      expect(include(:foo => eq(1))).to generate
      expect(include({ :foo => eq(1) }, { :a => :b })).to generate
    end

    it "generates nested collections" do
      matcher = include(
        :foo => :bar,
        :baz => [
          1, { :qux => be_a_kind_of(Rational) }
        ]
      )
      expect(matcher).to generate
    end
  end

  describe "contain_exactly" do
    it "generates an array" do
      expect(contain_exactly(1, 2, 3)).to generate
    end
  end

  describe "cover" do
    it "generates an inclusive range that covers the given values" do
      expect(cover(1)).to generate
      expect(cover(Date.new(2018, 1, 1), Date.new(2019, 1, 1), Date.new(2017, 1, 1))).to generate
    end
  end

  describe "end_with" do
    it "generates a string or array ending with the given value" do
      expect(end_with("foo")).to generate
      expect(end_with(1, 2)).to generate
    end
  end

  describe "start_with" do
    it "generates a string or array starting with the given value" do
      expect(start_with("foo")).to generate
      expect(start_with(1, 2)).to generate
    end
  end

  describe "have_attributes" do
    it "generates an object" do
      expect(have_attributes(:foo => "bar")).to generate
      expect(have_attributes(:foo => a_kind_of(String))).to generate
    end
  end

  describe "match" do
    it "can't match regexes" do
      expect { gen(match(/foo/)) }.to raise_error(ArgumentError)
    end

    it "generates regexes from strings" do
      expect(match("foo")).to generate
      expect(gen(match("foo"))).to eq(/foo/)
    end

    it "generates from matchers" do
      expect(match(a_string_including("str"))).to generate
    end

    it "generates hashes" do
      expect(match(:foo => "bar")).to generate
      expect(match(:foo => a_kind_of(String))).to generate
    end

    it "generates arrays" do
      expect(match([a_kind_of(String), a_kind_of(Integer)])).to generate
    end

    it "generates nested collections" do
      expect(match([a_kind_of(String), { :foo => 1 }])).to generate
    end
  end

  describe "respond_to" do
    it "generates objects with expected methods that return random values" do
      expect(respond_to(:foo)).to generate
      expect(respond_to(:foo, :bar)).to generate
    end

    it "can't generate methods with expected arities" do
      expect { gen(respond_to(:foo).with(2).arguments) }.to raise_error(ArgumentError)
      expect { gen(respond_to(:foo). with_any_keywords) }.to raise_error(ArgumentError)
    end
  end

  describe "satisfy" do
    it "can't generate" do
      expect { gen(satisfy { |x| x > 1 }) }.to raise_error(NotImplementedError)
    end
  end

  describe "exist" do
    it "doesn't generate" do
      expect { gen(exist) }.to raise_error(NotImplementedError)
    end
  end

  describe "output" do
    it "generates a proc that writes to stdout" do
      expect(output("foo").to_stdout).to generate
      expect(output(a_string_starting_with("foo")).to_stdout).to generate
    end

    it "generates a proc that writes to stderr" do
      expect(output("foo").to_stderr).to generate
      expect(output(a_string_starting_with("foo")).to_stderr).to generate
    end
  end

  describe "raise_error" do
    it "generates a block that raises the error" do
      expect(raise_error("foo")).to generate
      expect(raise_error(ArgumentError, "foo")).to generate
    end
  end

  describe "throw_symbol" do
    it "generates a block that throws" do
      expect(throw_symbol(:foo)).to generate
      expect(throw_symbol(:foo, "bar")).to generate
    end
  end

  describe "yield_control" do
    it "isn't supported, wouldn't be useful" do
      expect { gen(yield_control) }.to raise_error(NotImplementedError)
    end
  end

  describe "have_x" do
    it "doesn't generate" do
      expect { gen(have_key) }.to raise_error(NotImplementedError)
    end
  end

  describe "be_x" do
    it "doesn't generate" do
      expect { gen(be_positive) }.to raise_error(NotImplementedError)
    end
  end

  describe "custom generator" do
    it "overrides a matcher's generator" do
      negative_integer = RSpec::Generators.with_generator(be < 0, Radagen.fixnum_neg)
      expect(negative_integer).to generate
      expect(all(negative_integer)).to generate
    end
  end
end
