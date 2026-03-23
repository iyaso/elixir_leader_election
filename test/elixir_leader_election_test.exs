defmodule ElixirLeaderElectionTest do
  use ExUnit.Case
  doctest ElixirLeaderElection

  test "greets the world" do
    assert ElixirLeaderElection.hello() == :world
  end
end
