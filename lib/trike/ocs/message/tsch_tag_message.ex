defmodule OCS.Message.TschTagMessage do
  @moduledoc """
  TSCH TAG message type from OCS system
  """
  defstruct [:counter, :timestamp, :transitline, :trip_uid, :train_uid, :consist_tags, :car_tags]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitline: String.t(),
          trip_uid: String.t(),
          train_uid: String.t(),
          consist_tags: String.t(),
          car_tags: Enum.t()
        }
end
