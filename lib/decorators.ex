defmodule Decorators do

  defp make_decorated(func_name, args, body, {decor_name, _, _} = decorator) do
    new_name = binary_to_atom("_#{decor_name}_DECORATED_#{func_name}")
    quote do
      def unquote(new_name)(unquote_splicing(args)), unquote(body)
      def unquote(func_name)(unquote_splicing(args)) do
        __MODULE__.unquote(decorator)(unquote(new_name), unquote(args))
      end
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


end
