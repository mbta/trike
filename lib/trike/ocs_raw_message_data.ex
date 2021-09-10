defmodule Trike.OcsRawMessage do
  @moduledoc """
  The data payload of a com.mbta.ocs.raw_message CloudEvent.
  """
  @type t() :: %__MODULE__{
          received_time: DateTime.t(),
          raw: binary()
        }
  @derive Jason.Encoder
  @enforce_keys [:received_time, :raw]
  defstruct @enforce_keys
end
