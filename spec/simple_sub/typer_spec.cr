require "../spec_helper"

describe Typer do
  # These test cases are identical to those found here:
  # - https://github.com/LPTK/simple-sub/blob/4ec1af41dc3796622fa16ab3ca331d10ee2a12d4/shared/src/test/scala/simplesub/TypingTests.scala#L14-L22
  it "determines the obvious type of some basic terms" do
    TermLit[42]
      .should have_type("int")
    TermLam["x", TermLit[42]]
      .should have_type("(T -> int)")
    TermLam["x", TermVar["x"]]
      .should have_type("(α1 -> α1)")
    TermLam["x", TermApp[TermVar["x"], TermLit[42]]]
      .should have_type("((int -> α2) -> α2)")
    TermApp[TermLam["x", TermVar["x"]], TermLit[42]]
      .should have_type("int")
    TermLam["f",
      TermLam["x",
        TermApp[TermVar["f"],
          TermApp[TermVar["f"], TermVar["x"]]
        ]
      ]
      # Note: the original test says "((α2 | α4 -> α4) -> (α2 -> α4))",
      # but the following is also an acceptable inference for this case.
      # Which one we actually arrive at is dependent on order of execution
      # while unifying variables in the simplification algorithm.
    ].should have_type("((α2 -> α2 & α4) -> (α2 -> α4))")

    # TODO: doTest("let twice = fun f -> fun x -> f (f x) in twice", "('a ∨ 'b -> 'a) -> 'b -> 'a")
  end

  # These test cases are identical to those found here:
  # - https://github.com/LPTK/simple-sub/blob/4ec1af41dc3796622fa16ab3ca331d10ee2a12d4/shared/src/test/scala/simplesub/TypingTests.scala#L24-L42
  it "infers types related to booleans" do
    TermVar["true"]
      .should have_type("bool")
    TermApp[TermVar["not"], TermVar["true"]]
      .should have_type("bool")
    TermLam["x", TermApp[TermVar["not"], TermVar["x"]]]
      .should have_type("(bool -> bool)")
    TermApp[
      TermLam["x", TermApp[TermVar["not"], TermVar["x"]]],
      TermVar["true"]
    ].should have_type("bool")

    # TODO: The rest of these tests.
  end
end
