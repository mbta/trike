defmodule OCS.Message.TschTagMessage do
  @moduledoc """
  TSCH TAG message type from OCS system
  """
  alias OCS.Message.TschTagMessage.CarTag
  defstruct [:counter, :timestamp, :transitline, :trip_uid, :train_uid, :consist_tags, :car_tags]

  @type t :: %__MODULE__{
          counter: integer,
          timestamp: String.t(),
          transitline: String.t(),
          trip_uid: String.t(),
          train_uid: String.t(),
          consist_tags: list(String.t()),
          car_tags: list(CarTag.t())
        }
end

defmodule OCS.Message.TschTagMessage.CarTag do
  defstruct [:car_number, :car_number_display, :tag]

  @type t :: %__MODULE__{
          car_number: String.t(),
          car_number_display: String.t(),
          tag: String.t()
        }
end
