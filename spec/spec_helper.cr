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
    Typer.new.type_term(term).show
  end

  def match(term)
    @type_string == actual_type_string(term)
  end

  def failure_message(term : Term)
    <<-MSG
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
