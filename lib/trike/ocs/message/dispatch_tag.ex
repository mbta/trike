defmodule OCS.Message.DispatchTag do
  @moduledoc """
  These are the various tags that dispatchers can assign to trains; each is a single character
  """
  @spec parse_tags(binary()) :: list(String.t())
  def parse_tags(str) do
    str
    |> String.graphemes()
    |> Enum.reject(&Kernel.==(&1, " "))
  end
end
