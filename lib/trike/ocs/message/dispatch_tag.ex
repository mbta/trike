defmodule OCS.Message.DispatchTag do
  @moduledoc """
  These are the various tags that dispatchers can assign to trains; each is a single character
  """
  require Logger

  @tags_map %{
    "B" => :bypass,
    "X" => :express,
    "U" => :unload,
    "W" => :work_train,
    "S" => :last_train,
    "C" => :couple,
    "D" => :isolated,
    "K" => :restricted,
    "E" => :fis,
    "M" => :monitor_onboard,
    "A" => :run_as_directed,
    "L" => :light_extra,
    "N" => :snow_train,
    "T" => :temp
  }
  def parse(str) do
    if Map.has_key?(@tags_map, str) do
      @tags_map[str]
    else
      Logger.debug(str <> " is not a known dispatch tag")
      :unknown
    end
  end

  def parse_tags(str) do
    str
    |> String.graphemes()
    |> Enum.reject(&Kernel.==(&1, " "))
    |> Enum.map(&parse/1)
  end
end
