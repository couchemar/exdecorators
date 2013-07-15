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

  defmacro __before_compile__(env) do
    m = env.module
    decorated = Module.get_attribute(env.module, :decorated)
    decorators = Module.get_attribute(env.module, :decorators)

    to_decor = lc f inlist decorated do
      {f, Module.get_attribute(env.module, binary_to_atom("decorators_for_#{f}"))}
    end

    lc {f, d} inlist to_decor do
      args = decorators[d]
      new_name = binary_to_atom("_#{d}_DECORATED_#{f}")
      quote do
        def unquote(f)(unquote_splicing(args)) do
          decorated = Decorated.new(module: unquote(m),
                                    decorated: unquote(new_name),
                                    origin: unquote(f))
          unquote(m).unquote(d)(decorated, unquote_splicing(args))
        end
      end

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


  defmacro decorate(decorator, func_and_body) do
    {:def, _ctx, [{func_name, _fun_ctx, args}, body]} = func_and_body
    make_decorated(func_name, args, body, decorator)
  end

  defmacro decorate(decorator, definition, body) do
    {:def, _ctx, [{func_name, _fun_ctx, args}]} = definition
    make_decorated(func_name, args, body, decorator)
  end

  defp make_decorated(func_name, args, body, {decor_name, _, _}) do
    new_name = binary_to_atom("_#{decor_name}_DECORATED_#{func_name}")
    function_decorators = binary_to_atom("decorators_for_#{func_name}")
    quote do
      def unquote(new_name)(unquote_splicing(args)), unquote(body)
      Module.put_attribute __MODULE__, :decorated, unquote(func_name)
      Module.put_attribute __MODULE__, unquote(function_decorators), unquote(decor_name)
    end
  end

end
