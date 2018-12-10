RSpec.describe RSpec::Generators do
  RSpec::Matchers.define :generate do |expected|
    match do |actual|
      begin
        RSpec::Generators.generator(actual).to_enum(seed: seed).first(10)
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

  describe "be" do
    it "generates the expected value" do
      expect(be(Object.new)).to generate
    end

    it "generates for simple comparisons" do
      expect(be > 0).to generate
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
      expect(send(matcher, Integer)).to generate
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
