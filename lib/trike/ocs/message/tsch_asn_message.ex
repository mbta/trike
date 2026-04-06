defmodule OCS.Message.TschAsnMessage do
  @moduledoc """
  TSCH ASN message type from OCS system
  """
  defstruct [:counter, :timestamp, :transitline, :train_uid, :trip_uid]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: DateTime.t(),
          transitline: String.t(),
          train_uid: String.t(),
          trip_uid: String.t()
        }
end
