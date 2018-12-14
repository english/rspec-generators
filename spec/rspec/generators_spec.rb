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

  describe "be_instance_of" do
    it_behaves_like "kind_of", :be_instance_of
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

  describe "custom generator" do
    it "overrides a matcher's generator" do
      negative_integer = RSpec::Generators.with_generator(be < 0, Radagen.fixnum_neg)
      expect(negative_integer).to generate
      expect(all(negative_integer)).to generate
    end
  end

  # TODO:
  #
  # ```
  # autoload :BeNil,                   'rspec/matchers/built_in/be'
  # autoload :BePredicate,             'rspec/matchers/built_in/be'
  # autoload :BeTruthy,                'rspec/matchers/built_in/be'
  # autoload :BeWithin,                'rspec/matchers/built_in/be_within'
  # autoload :Change,                  'rspec/matchers/built_in/change'
  # autoload :ContainExactly,          'rspec/matchers/built_in/contain_exactly'
  # autoload :Cover,                   'rspec/matchers/built_in/cover'
  # autoload :EndWith,                 'rspec/matchers/built_in/start_or_end_with'
  # autoload :Eql,                     'rspec/matchers/built_in/eql'
  # autoload :Exist,                   'rspec/matchers/built_in/exist'
  # autoload :Has,                     'rspec/matchers/built_in/has'
  # autoload :HaveAttributes,          'rspec/matchers/built_in/have_attributes'
  # autoload :Match,                   'rspec/matchers/built_in/match'
  # autoload :NegativeOperatorMatcher, 'rspec/matchers/built_in/operators'
  # autoload :OperatorMatcher,         'rspec/matchers/built_in/operators'
  # autoload :Output,                  'rspec/matchers/built_in/output'
  # autoload :PositiveOperatorMatcher, 'rspec/matchers/built_in/operators'
  # autoload :RaiseError,              'rspec/matchers/built_in/raise_error'
  # autoload :RespondTo,               'rspec/matchers/built_in/respond_to'
  # autoload :Satisfy,                 'rspec/matchers/built_in/satisfy'
  # autoload :StartWith,               'rspec/matchers/built_in/start_or_end_with'
  # autoload :ThrowSymbol,             'rspec/matchers/built_in/throw_symbol'
  # autoload :YieldControl,            'rspec/matchers/built_in/yield'
  # autoload :YieldSuccessiveArgs,     'rspec/matchers/built_in/yield'
  # autoload :YieldWithArgs,           'rspec/matchers/built_in/yield'
  # autoload :YieldWithNoArgs,         'rspec/matchers/built_in/yield'
  # ```
  #
  # DONE:
  #
  # ```
  # autoload :Eq,                      'rspec/matchers/built_in/eq'
  # autoload :Equal,                   'rspec/matchers/built_in/equal'
  # autoload :Compound,                'rspec/matchers/built_in/compound'
  # autoload :BeAKindOf,               'rspec/matchers/built_in/be_kind_of'
  # autoload :All,                     'rspec/matchers/built_in/all'
  # autoload :Include,                 'rspec/matchers/built_in/include'
  # autoload :BeComparedTo,            'rspec/matchers/built_in/be'
  # autoload :BeAnInstanceOf,          'rspec/matchers/built_in/be_instance_of'
  # autoload :BeBetween,               'rspec/matchers/built_in/be_between'
  # autoload :Be,                      'rspec/matchers/built_in/be'
  # autoload :BeFalsey,                'rspec/matchers/built_in/be'
  # ```
end
