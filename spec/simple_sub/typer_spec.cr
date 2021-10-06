require "../spec_helper"

describe Typer do
  it "determines the obvious type of some basic terms" do
    typer = Typer.new
    typer.type_term(TermLit.new(42)).show.should eq("int")
  end
end
