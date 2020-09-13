ExUnit.start()

defmodule FProf do
  defmacro profile(do: block) do
    content =
      quote do
        Mix.Tasks.Profile.Fprof.profile(fn -> unquote(block) end,
          warmup: false,
          sort: "acc",
          callers: true
        )
      end

    Code.compile_quoted(content)
  end
end
