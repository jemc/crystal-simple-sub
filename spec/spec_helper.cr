require "spec"
require "../src/simple_sub"

include SimpleSub

# Introduce an expectation that the left side term should be inferred by
# the SimpleSub::Typer as having a type whose string matches the right side.
def have_type(type_string)
  SimpleSub::TypeExpectation.new(type_string)
end

class SimpleSub::TypeExpectation
  @type_string : String

  def initialize(@type_string)
  end

  def actual_type_string(term : Term)
    CompactType.simplified_from(Typer.new.infer_type(term)).show
  end

  def pre_simplification_type_information(term : Term)
    String.build { |io|
      pre_type = Typer.new.infer_type(term)

      io << "\n\nThe type given by the initial typer was:\n"
      io << pre_type.show

      analysis = CompactType::Analysis.new
      polarity = true
      type = CompactType.from(pre_type, polarity, analysis)
      type.analyze_co_occurrences(polarity, analysis)

      io << "\n\nThe variable bounds were:"
      analysis.show_all_vars(io)

      io << "\n\nThe co-occurrences were:"
      analysis.show_co_occurrences(io)

      io << "\n\nThe initial compact type was:\n"
      type.show(io)
    }
  end

  def match(term)
    @type_string == actual_type_string(term)
  end

  def failure_message(term : Term)
    <<-MSG
    #{term.pretty_inspect}

    ---#{pre_simplification_type_information(term)}

    ---

    Expected type: #{@type_string}
          got type: #{actual_type_string(term)}
    MSG
  end

  def negative_failure_message(term : Term)
    <<-MSG
      Expected not to have type: #{@type_string}
    MSG
  end
end
