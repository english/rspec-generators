require "rspec/generators/version"
require "rspec/expectations"
require "radagen"
require "set"

module RSpec
  module Generators
    module Refinements
      refine Object do
        def rspec_generators_generator=(generator)
          @rspec_generators_generator = generator
        end

        def rspec_generators_generator
          @rspec_generators_generator
        end

        def generator
          rspec_generators_generator || _generator
        end

        def _generator
          Radagen.return(self)
        end
      end

      refine Integer.singleton_class do
        def _generator
          Radagen.fixnum
        end
      end

      refine String.singleton_class do
        def _generator
          Radagen.string
        end
      end

      refine Float.singleton_class do
        def _generator
          Radagen.float
        end
      end

      refine Symbol.singleton_class do
        def _generator
          Radagen.symbol
        end
      end

      refine Array.singleton_class do
        def _generator
          Radagen.array(Radagen.simple_type)
        end
      end

      refine Set.singleton_class do
        def _generator
          Radagen.set(Radagen.simple_type)
        end
      end

      refine Hash.singleton_class do
        def _generator
          Radagen.hash_map(Radagen.simple_type, Radagen.simple_type)
        end
      end

      refine Rational.singleton_class do
        def _generator
          Radagen.rational
        end
      end

      refine Hash do
        def _generator
          Radagen.hash(Hash[self.map { |k, v| [k, v.generator] }])
        end
      end

      refine Array do
        def _generator
          Radagen.tuple(*map { |x| x.generator })
        end
      end

      refine RSpec::Matchers::BuiltIn::BaseMatcher do
        def _generator
          raise NotImplementedError
        end
      end

      refine RSpec::Matchers::BuiltIn::Eq do
        def _generator
          Radagen.fmap(Radagen.return(expected)) do |genned|
            Numeric === genned ?
              genned :
              genned.clone
          end
        end
      end

      refine RSpec::Matchers::BuiltIn::Eql do
        def _generator
          Radagen.fmap(Radagen.return(expected), &:clone)
        end
      end

      refine RSpec::Matchers::BuiltIn::Equal do
        def _generator
          Radagen.return(expected)
        end
      end

      refine RSpec::Matchers::BuiltIn::Compound::Or do
        def _generator
          Radagen.one_of(matcher_1.generator, matcher_2.generator)
        end
      end

      refine RSpec::Matchers::BuiltIn::Compound::And do
        def _generator
          matcher_1.generator
        end
      end

      refine RSpec::Matchers::BuiltIn::BeAKindOf do
        def _generator
          expected.generator
        end
      end

      refine RSpec::Matchers::BuiltIn::BeAnInstanceOf do
        def _generator
          expected.generator
        end
      end

      refine RSpec::Matchers::BuiltIn::All do
        def _generator
          Radagen.array(matcher.generator)
        end
      end

      refine RSpec::Matchers::BuiltIn::Include do
        def _generator
          if expecteds.count == 1 && Hash === expecteds.first
            expecteds.first.generator
          else
            Radagen.tuple(*expecteds.map { |x| x.generator })
          end
        end
      end

      refine RSpec::Matchers::BuiltIn::BeComparedTo do
        def _generator
          expected.class.generator
        end
      end

      refine RSpec::Matchers::BuiltIn::BeBetween do
        def _generator
          Radagen.choose(@min, @max)
        end
      end

      refine RSpec::Matchers::BuiltIn::BeFalsey do
        def _generator
          Radagen.one_of(Radagen.return(false), Radagen.return(nil))
        end
      end

      refine RSpec::Matchers::BuiltIn::BeTruthy do
        def _generator
          Radagen.such_that(Radagen.simple_printable, &:itself)
        end
      end

      refine RSpec::Matchers::BuiltIn::BeNil do
        def _generator
          Radagen.return(nil)
        end
      end

      refine RSpec::Matchers::BuiltIn::BeWithin do
        def _generator
          Radagen.choose(@expected - @tolerance, @expected + @tolerance)
        end
      end

      refine RSpec::Matchers::BuiltIn::ContainExactly do
        def _generator
          Radagen.bind(expected.generator) { |coll| Radagen.shuffle(coll) }
        end
      end

      refine RSpec::Matchers::BuiltIn::Cover do
        def _generator
          Radagen.return(@expected.min..@expected.max)
        end
      end

      refine RSpec::Matchers::BuiltIn::EndWith do
        def _generator
          Radagen.fmap(expected.class.generator) { |genned| genned + expected }
        end
      end

      refine RSpec::Matchers::BuiltIn::StartWith do
        def _generator
          Radagen.fmap(expected.class.generator) { |genned| expected + genned }
        end
      end

      refine RSpec::Matchers::BuiltIn::HaveAttributes do
        def _generator
          Radagen.fmap(expected.generator) { |hash|
            hash.each_with_object(Object.new) do |(method_name, return_value), object|
              object.define_singleton_method(method_name) { return_value }
            end
          }
        end
      end

      refine RSpec::Matchers::BuiltIn::Match do
        def _generator
          case expected
          when Regexp
            raise ArgumentError, "cannot generate string from regex"
          when String
            Radagen.return(Regexp.new(expected))
          else
            expected.generator
          end
        end
      end

      refine RSpec::Matchers::BuiltIn::RespondTo do
        def _generator
          if @expected_arity || @expected_keywords.any? || @unlimited_arguments || @arbitrary_keywords
            raise ArgumentError, "can't generate methods with specific arities"
          end

          return_values_generators = Radagen.array(Radagen.simple_printable, :count => @names.count)
          Radagen.fmap(return_values_generators) { |return_values|
            @names.zip(return_values).each_with_object(Object.new) do |(method_name, return_value), object|
              object.define_singleton_method(method_name) { return_value }
            end
          }
        end
      end

      refine RSpec::Matchers::BuiltIn::Output do
        def _generator
          value_generator = expected ? expected.generator : Radagen.string

          Radagen.fmap(value_generator) { |val|
            -> {
              io = @stream_capturer.name == "stdout" ? $stdout : $stderr
              io.print(val)
            }
          }
        end
      end

      refine RSpec::Matchers::BuiltIn::RaiseError do
        def _generator
          error_class = @expected_error || RuntimeError
          error_message_generator = Radagen.return(@expected_message) || Radagen.simple_printable

          Radagen.fmap(error_message_generator) { |error_message|
            -> { raise error_class, error_message }
          }
        end
      end

      refine RSpec::Matchers::BuiltIn::ThrowSymbol do
        def _generator
          Radagen.return(-> {
            if @expected_arg
              throw @expected_symbol, @expected_arg
            else
              throw @expected_symbol
            end
          })
        end
      end

      refine RSpec::Matchers::AliasedMatcher do
        def _generator
          base_matcher.generator
        end
      end
    end

    using Refinements

    def self.generator(matcher)
      Radagen.such_that(matcher.generator) { |genned| matcher === genned }
    end

    def self.with_generator(matcher, generator)
      matcher.clone.tap do |clone|
        clone.rspec_generators_generator = generator
      end
    end
  end
end
