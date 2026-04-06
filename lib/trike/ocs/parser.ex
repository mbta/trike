defmodule OCS.Parser do
  @moduledoc """
  This module parses a string consisting of comma-separated values into a tuple
  of the form {count, type, time, rest}
  count -> The sequence counter of the message (int)
  type -> an atom for the message type (:tmov, :tsch, :devi)
  time -> a Time sigil for the timestamp of the message
  rest -> a list of the remaining values from the message
  """

  defmodule UnimplementedMessageTypeError do
    defexception message: "ocs message type has not been implemented in parser"
  end

  @spec parse(String.t(), DateTime.t()) :: {:ok, OCS.Message.t()} | {:error, any}
  def parse(line, current_time) do
    {:ok, parse!(line, current_time)}
  rescue
    e -> {:error, e}
  end

  @spec parse!(String.t(), DateTime.t()) :: OCS.Message.t()
  def parse!(line, current_time) do
    line
    |> parse_initial(current_time)
    |> parse_by_msg_type(current_time)
    |> case do
      {:ok, msg} -> msg
      {:error, e} -> raise e
    end
  end

  defp parse_initial(line, current_time) do
    [counter, msg_type, msg_time | rest] = String.split(line, ",")
    {count, ""} = Integer.parse(counter)

    type =
      try do
        String.to_existing_atom(String.downcase(msg_type))
      rescue
        ArgumentError -> msg_type
      end

    time = get_time(msg_time, current_time)
    {count, type, time, rest}
  end

  defp parse_by_msg_type(msg, current_time) do
    case msg do
      {_count, :tsch, _timestamp, _args} ->
        OCS.Parser.TschMessage.parse(msg, current_time)

      # Remaining valid message types are unimplemented for now
      {_count, :tmov, _timestamp, _args} ->
        {:error, %UnimplementedMessageTypeError{}}

      {_count, :devi, _timestamp, _args} ->
        {:error, %UnimplementedMessageTypeError{}}

      {_count, :diag, _timestamp, _args} ->
        {:error, %UnimplementedMessageTypeError{}}

      {_count, :rgps, _timestamp, _args} ->
        {:error, %UnimplementedMessageTypeError{}}

      {_count, msg_type, _timestamp, _args} ->
        {:error, "Message type #{msg_type} did not match any expected message"}
    end
  end

  @spec get_time(String.t(), DateTime.t()) :: DateTime.t()
  defp get_time(msg_time, current_time) do
    # allow msg_time to be up to one hour in the future; otherwise assume it is from yesterday
    time = Timex.parse!(msg_time, "{h24}:{m}:{s}")
    dt = Timex.set(current_time, hour: time.hour, minute: time.minute, second: time.second)

    if Timex.before?(dt, Timex.shift(current_time, hours: 1)) do
      dt
    else
      Timex.shift(dt, days: -1)
    end
  end

  # OCS can't handle car numbers duplicated across transit lines.
  # Starting in 2023, new 1500-series Orange Line cars have arrived before
  # the 1500 Red Line cars are retired.
  # So in January 2024 the OCC started inputting the Red Line 15xx cars as 25xx.
  # Map them back to 15xx.
  @spec convert_ocs_car_number(String.t(), String.t()) :: String.t()
  def convert_ocs_car_number("R", "25" <> car_number_rest) do
    "15" <> car_number_rest
  end

  def convert_ocs_car_number(_transitline, car_number) do
    car_number
  end
end
