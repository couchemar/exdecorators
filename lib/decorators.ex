defmodule Decorators do
  defrecord Decorated, module: nil,
                       decorated: nil,
                       origin: nil do
    def call(args, __MODULE__[module: module, decorated: decorated]) do
      apply(module, decorated, args)
    end
  end

  defmacro __using__(_options) do
    quote do
      Module.register_attribute __MODULE__, :decorators,
             accumulate: true,
             persist: false

      Module.register_attribute __MODULE__, :decorated,
             accumulate: true,
             persist: false

      import unquote(__MODULE__)
      @before_compile unquote(__MODULE__)
    end
  end

  def make_decoration(module, {f_name, _, _}=f) do
    make_decoration(module, f, Module.get_attribute(module, binary_to_atom("decorators_for_#{f_name}")))
  end

  def make_decoration(module, {f_name, f_args, f_body}, decor_name) do
    # Decorated function
    new_name = binary_to_atom("_#{decor_name}_DECORATED_#{f_name}")
    decorated_function = quote do
      def unquote(new_name)(unquote_splicing(f_args)), unquote(f_body)
    end

    # Decorator
    decorators_list = Module.get_attribute(module, :decorators)
    d_args = decorators_list[decor_name]
    decorator = quote do
      def unquote(f_name)(unquote_splicing(d_args)) do
        decorated = Decorated.new(module: unquote(module),
                                  decorated: unquote(new_name),
                                  origin: unquote(f_name))
        unquote(module).unquote(decor_name)(decorated, unquote_splicing(d_args))
      end
    end
    [decorated_function, decorator]
  end

  defmacro __before_compile__(env) do
    m = env.module
    decorated = Module.get_attribute(env.module, :decorated)
    lc f inlist decorated do
      make_decoration(m, f)
    end
  end

  defmacro defdecorator(decorator, options, body) do
    {deco_name, _ctx, deco_args} = decorator
    args = options[:args]
    new_args = deco_args ++ args

    quote do
      @decorators {unquote(deco_name), unquote(Macro.escape args)}
      def unquote(deco_name)(unquote_splicing(new_args)), unquote(body)
    end
  end

  defmacro decorate({decor_name, _, _},
                    {:def, _ctx, [{func_name, _fun_ctx, args}, body]}) do
    mark_decorated(func_name, args, body, decor_name)
  end

  defmacro decorate({decor_name, _, _},
                    {:def, _ctx, [{func_name, _fun_ctx, args}]},
                    body) do
    mark_decorated(func_name, args, body, decor_name)
  end

  defp mark_decorated(func_name, args, body, decor_name) do
    function_decorators = binary_to_atom("decorators_for_#{func_name}")
    quote do
      Module.put_attribute __MODULE__, :decorated, {unquote(func_name), unquote(Macro.escape args), unquote(Macro.escape body)}
      Module.put_attribute __MODULE__, unquote(function_decorators), unquote(decor_name)
    end
  end
end
