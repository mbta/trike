defmodule OCS.Message.TschDelMessage do
  @moduledoc """
  TSCH DEL message type from OCS system
  """
  defstruct [:counter, :timestamp, :transitline, :trip_uid, :delete_status]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitline: String.t(),
          trip_uid: String.t(),
          delete_status: :deleted | :undeleted
        }
end
