require "../spec_helper"

describe Typer do
  # These test cases are identical to those found here:
  # - https://github.com/LPTK/simple-sub/blob/4ec1af41dc3796622fa16ab3ca331d10ee2a12d4/shared/src/test/scala/simplesub/TypingTests.scala#L14-L22
  it "determines the obvious type of some basic terms" do
    TermLit.new(42)
      .should have_type("int")
    TermLam.new("x", TermLit.new(42))
      .should have_type("(T -> int)")
    TermLam.new("x", TermVar.new("x"))
      .should have_type("(α1 -> α1)")
    TermLam.new("x", TermApp.new(TermVar.new("x"), TermLit.new(42)))
      .should have_type("((int -> α2) -> α2)")
    TermApp.new(TermLam.new("x", TermVar.new("x")), TermLit.new(42))
      .should have_type("int")
  end
end
