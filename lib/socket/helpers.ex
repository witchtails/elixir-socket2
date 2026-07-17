defmodule Socket.Helpers do
  defmacro __using__(_opts) do
    quote do
      import Socket.Helpers
    end
  end

  @doc """
  Unwrap the result of a socket call, raising `Socket.Error` on failure.

  Used by the `defbang` macro. Keeping the pattern match in a runtime function
  (rather than inline at the call site) avoids "clause will never match"
  warnings when the wrapped function has a narrower return type.
  """
  def bang(:ok), do: :ok
  def bang({:ok, result}), do: result
  def bang({:error, reason}), do: raise(Socket.Error, reason: reason)

  defmacro defbang({name, _, args}) do
    args = if is_list(args), do: args, else: []

    quote bind_quoted: [name: Macro.escape(name), args: Macro.escape(args)] do
      def unquote((to_string(name) <> "!") |> String.to_atom())(unquote_splicing(args)) do
        Socket.Helpers.bang(unquote(name)(unquote_splicing(args)))
      end
    end
  end

  defmacro defbang({name, _, args}, to: mod) do
    args = if is_list(args), do: args, else: []

    quote bind_quoted: [
            mod: Macro.escape(mod),
            name: Macro.escape(name),
            args: Macro.escape(args)
          ] do
      def unquote((to_string(name) <> "!") |> String.to_atom())(unquote_splicing(args)) do
        Socket.Helpers.bang(unquote(mod).unquote(name)(unquote_splicing(args)))
      end
    end
  end

  defmacro defwrap({name, _, [self | args]}, options \\ []) do
    if instance = options[:to] do
      quote bind_quoted: [
              name: Macro.escape(name),
              self: Macro.escape(self),
              args: Macro.escape(args),
              instance: Macro.escape(instance),
              field: options[:field] || :socket
            ] do
        def unquote(name)(unquote(self), unquote_splicing(args)) do
          unquote(self).unquote(field)
          |> @protocol.unquote(instance).unquote(name)(unquote_splicing(args))
        end
      end
    else
      quote bind_quoted: [
              name: Macro.escape(name),
              self: Macro.escape(self),
              args: Macro.escape(args),
              field: options[:field] || :socket
            ] do
        def unquote(name)(unquote(self), unquote_splicing(args)) do
          unquote(self).unquote(field) |> @protocol.unquote(name)(unquote_splicing(args))
        end
      end
    end
  end

  defmacro definvalid({name, _, args}) do
    args =
      if args |> is_list do
        for {_, meta, context} <- args do
          {:_, meta, context}
        end
      else
        []
      end

    quote do
      def unquote(name)(unquote_splicing(args)) do
        {:error, :einval}
      end
    end
  end
end
