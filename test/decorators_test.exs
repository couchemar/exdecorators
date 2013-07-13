Code.require_file "test_helper.exs", __DIR__

defmodule TestModule do
  import Decorators

  def d1(func, args), do: apply(__MODULE__, func, args)
  def d2(_func, _args), do: 2

  decorate d1,
  def f1(a) do
    a
  end

  decorate d2,
  (def f2(), do: 1)

end

defmodule DecoratorsTest do
  use ExUnit.Case

  test "simple" do
    assert 1 == TestModule.f1(1)
    assert 2 == TestModule.f2()
  end

end
