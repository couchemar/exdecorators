defmodule Decorators do

  defmacro defdecorator(decorator, options, body) do
    {deco_name, _ctx, deco_args} = decorator
    args = options[:args]
    new_args = deco_args ++ args
    quote do
      def unquote(deco_name)(unquote_splicing(new_args)), unquote(body)
    end
  end

  defrecord Decorated, module: nil,
                       decorated: nil,
                       origin: nil do
    def call(args, __MODULE__[module: module, decorated: decorated]=this) do
      apply(module, decorated, args)
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

  defp make_decorated(func_name, args, body, {decor_name, _, _} = decorator) do
    new_name = binary_to_atom("_#{decor_name}_DECORATED_#{func_name}")
    quote do
      def unquote(new_name)(unquote_splicing(args)), unquote(body)
      def unquote(func_name)(unquote_splicing(args)) do
        decorated = Decorated.new(module: __MODULE__,
                                  decorated: unquote(new_name),
                                  origin: unquote(func_name))
        __MODULE__.unquote(decorator)(decorated, unquote_splicing(args))
      end
    end
  end

end
