Code.require_file "test_helper.exs", __DIR__

defmodule TestModule do
  import Decorators

  defdecorator d1(decorated), args: [a] do
    decorated.call([a])
  end

  decorate d1,
  def f1(a) do
    a
  end

end

defmodule DecoratorsTest do
  use ExUnit.Case

  test "simple" do
    assert 1 == TestModule.f1(1)
  end

end
