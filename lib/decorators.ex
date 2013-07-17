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

  def decorate_function(module, f_name, d_name, new_name) do
    decorators_list = Module.get_attribute(module, :decorators)
    d_args = decorators_list[d_name]
    quote do
      def unquote(f_name)(unquote_splicing(d_args)) do
        decorated = Decorated.new(module: unquote(module),
                                  decorated: unquote(new_name),
                                  origin: unquote(f_name))
        unquote(module).unquote(d_name)(decorated, unquote_splicing(d_args))
      end
    end
  end

  def decorate_decorators(module, decorated_name, decorators, last_decor_name) when length(decorators)>0 do
    decorate_decorators(module, decorated_name, decorators, [], last_decor_name)
  end

  def decorate_decorators(_module, decorated_name, [], last_decor_name) do
    {decorated_name, last_decor_name, []}
  end

  def decorate_decorators(module, decorated_name, [decor_name|decorators], acc, last_decor_name) do
    new_name = binary_to_atom("_#{decor_name}_DECORATED_#{decorated_name}")

    decorated = decorate_function(module, new_name, last_decor_name, decorated_name)
    decorate_decorators(module, new_name, decorators, [decorated|acc], decor_name)
  end

  def decorate_decorators(_module, decorated_name, [], acc, last_decor_name) do
    {decorated_name, last_decor_name, acc}
  end

  def make_decoration(module, {f_name, f_args, f_body, [decor_name|decorators]}) do
    # Decorated function
    new_name = binary_to_atom("_#{decor_name}_DECORATED_#{f_name}")
    decorated_function = quote do
      def unquote(new_name)(unquote_splicing(f_args)), unquote(f_body)
    end

    # Decorators
    {new_name, last_d_name, decorators} = decorate_decorators(module, new_name,
                                                              decorators, decor_name)

    last_decorator = decorate_function(module, f_name, last_d_name, new_name)
    decorators = [last_decorator|decorators]

    [decorated_function|decorators]
  end

  defmacro __before_compile__(env) do
    m = env.module
    decorated = Module.get_attribute(m, :decorated)
    decorated = lc f inlist decorated do
      make_decoration(m, f)
    end

    # No need more @decorated @decorators
    Module.delete_attribute m, :decorators
    Module.delete_attribute m, :decorated

    decorated
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
    mark_decorated(func_name, args, body, [decor_name])
  end

  defmacro decorate({decor_name, _, _},
                    {:def, _ctx, [{func_name, _fun_ctx, args}]},
                    body) do
    mark_decorated(func_name, args, body, [decor_name])
  end

  defmacro decorate(decorators,
                    {:def, _ctx, [{func_name, _fun_ctx, args}]},
                    body) when is_list(decorators)do
    decor_names = lc {decor_name, _, _} inlist decorators, do: decor_name
    mark_decorated(func_name, args, body, decor_names)
  end

  defp mark_decorated(func_name, args, body, decor_names) do
    quote do
      Module.put_attribute __MODULE__, :decorated, {unquote(func_name), unquote(Macro.escape args), unquote(Macro.escape body), unquote(decor_names)}
    end
  end
end
