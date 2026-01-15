defmodule OCS.Message.TschLnkMessage do
  @moduledoc """
  TSCH LNK message type from OCS system
  """
  defstruct [:counter, :timestamp, :transitline, :trip_uid, :prev_trip_uid, :next_trip_uid]

  @type t :: %__MODULE__{
          counter: integer | nil,
          timestamp: String.t() | nil,
          transitline: String.t() | nil,
          trip_uid: String.t(),
          prev_trip_uid: String.t() | nil,
          next_trip_uid: String.t() | nil
        }
end
