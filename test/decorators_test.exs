Code.require_file "test_helper.exs", __DIR__

defmodule TestModule do
  import Decorators
  use Decorators

  defdecorator d1(decorated), args: [a] do
    decorated.call([a])
  end

  decorate d1,
  def f1(a) do
    a
  end

  defdecorator d2(decorated), args: [a] do
    a + decorated.call([])
  end

  decorate d2,
  def f2() do
    1
  end

  defdecorator d3(decorated), args: [a, b] do
    a + b + decorated.call([])
  end

  decorate d3,
  def f3() do
    2
  end

  defdecorator d4(decorated), args: [a] do
    1 + decorated.call([a])
  end

  defdecorator d5(decorated), args: [a] do
    2 + decorated.call([a])
  end

  decorate [d4, d5],
  def f4(a) do
    a
  end

end

defmodule DecoratorsTest do
  use ExUnit.Case

  test "simple" do
    assert 1 == TestModule.f1(1)
    assert 2 == TestModule.f2(1)
    assert 5 == TestModule.f3(1, 2)
  end

  test "multiple" do
    assert 4 == TestModule.f4(1)
  end
end
