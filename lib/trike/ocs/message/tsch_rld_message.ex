defmodule OCS.Message.TschRldMessage do
  @moduledoc """
  TSCH RLD message type from OCS system
  """
  defstruct [:counter, :timestamp, :transitline]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitline: String.t()
        }
end
