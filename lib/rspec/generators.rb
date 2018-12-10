require "rspec/generators/version"
require "rspec/expectations"
require "radagen"
require "set"

module RSpec
  module Generators
    using Module.new {
      CLASS_GENS = {
        Integer  => Radagen.fixnum,
        String   => Radagen.string,
        Float    => Radagen.float,
        Symbol   => Radagen.symbol,
        Array    => Radagen.array(Radagen.simple_type),
        Set      => Radagen.set(Radagen.simple_type),
        Hash     => Radagen.hash_map(Radagen.simple_type, Radagen.simple_type),
        Rational => Radagen.rational,
      }

      refine Object do
        attr_accessor :rspec_generators_generator

        def generator
          rspec_generators_generator || _generator
        end

        def _generator
          Radagen.return(self)
        end
      end

      refine Hash do
        def _generator
          Radagen.hash(Hash[self.map { |k, v| [k, v.generator] }])
        end
      end

      refine Array do
        def _generator
          Radagen.tuple(*self.map(&:generator))
        end
      end

      refine Set do
        def _generator
          Radagen.tuple(*self.map(&:generator)).fmap { |array| Set.new(array) }
        end
      end

      refine RSpec::Matchers::BuiltIn::Eq do
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
          CLASS_GENS.fetch(expected)
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
            Radagen.tuple(*expecteds.map(&:generator))
          end
        end
      end

      refine RSpec::Matchers::BuiltIn::BeComparedTo do
        def _generator
          CLASS_GENS.fetch(expected.class)
        end
      end

      refine RSpec::Matchers::AliasedMatcher do
        def _generator
          base_matcher.generator
        end
      end
    }

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
