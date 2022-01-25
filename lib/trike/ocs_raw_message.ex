defmodule Trike.OcsRawMessage do
  @moduledoc """
  The data payload of a com.mbta.ocs.raw_message CloudEvent.
  """
  @type t() :: %__MODULE__{raw: binary()}
  @derive Jason.Encoder
  @enforce_keys [:raw]
  defstruct @enforce_keys
end
