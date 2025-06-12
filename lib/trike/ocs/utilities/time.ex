defmodule OCS.Utilities.Time do
  @moduledoc """
  Some utility functions for dealing with times
  """
  require FastLocalDatetime
  require Logger

  @service_date_hour_cutoff 2

  @spec parse_gtfs_time(String.t()) :: integer | nil
  def parse_gtfs_time(""), do: nil

  def parse_gtfs_time(time) when is_binary(time) do
    [hrs, mins, secs] = String.split(time, ":")
    String.to_integer(hrs) * 3600 + String.to_integer(mins) * 60 + String.to_integer(secs)
  end

  @spec parse_tsch_msg_time(String.t()) :: integer | nil
  def parse_tsch_msg_time(time) when is_binary(time) do
    [hrs, mins] = String.split(time, ":")
    hours = String.to_integer(hrs)
    hours = if hours < @service_date_hour_cutoff, do: hours + 24, else: hours
    hours * 3600 + String.to_integer(mins) * 60
  end

  @spec in_rtr_tz(
          Date.t() | DateTime.t() | NaiveDateTime.t() | integer(),
          String.t()
        ) ::
          DateTime.t()
  def in_rtr_tz(datetime, timezone \\ Application.get_env(:rtr, :time_zone))

  def in_rtr_tz(%Date{} = date, timezone) do
    {:ok, ndt} = NaiveDateTime.new(date, ~T[00:00:00])
    in_rtr_tz(ndt, timezone)
  end

  def in_rtr_tz(%DateTime{time_zone: time_zone} = datetime, time_zone) do
    datetime
  end

  def in_rtr_tz(%DateTime{} = time, time_zone) do
    # There _shouldn't_ be any DateTime's in the wrong tz. Adding logging
    # to run for a while and see if it comes up.
    Logger.warning("event=dt_in_wrong_tz DateTime not in same zone: #{inspect(time)}")
    Logger.info("#{inspect(Process.info(self(), :current_stacktrace))}")
    {:ok, new_dt} = DateTime.shift_zone(time, time_zone)
    new_dt
  end

  def in_rtr_tz(%NaiveDateTime{} = time, timezone) do
    naive_to_datetime(time, timezone)
  end

  def in_rtr_tz(time, timezone) when is_integer(time) do
    {:ok, new_dt} = DateTime.from_unix(time)
    {:ok, new_dt} = DateTime.shift_zone(new_dt, timezone)
    new_dt
  end

  @spec local_now(Timex.Types.valid_timezone()) :: DateTime.t()
  def local_now(timezone \\ Application.get_env(:rtr, :time_zone)) do
    {:ok, dt} = DateTime.now(timezone)
    dt
  end

  @spec get_seconds_since_midnight(NaiveDateTime.t() | DateTime.t() | integer) :: integer
  def get_seconds_since_midnight(%NaiveDateTime{} = current_time) do
    current_time
    |> in_rtr_tz
    |> get_seconds_since_midnight
  end

  def get_seconds_since_midnight(%DateTime{} = current_time) do
    pseudo_midnight_unix =
      current_time |> get_service_date() |> service_date_pseudo_midnight_unix()

    DateTime.to_unix(current_time) - pseudo_midnight_unix
  end

  def get_seconds_since_midnight(current_time) when is_integer(current_time) do
    timezone = Application.get_env(:rtr, :time_zone)

    current_time
    |> FastLocalDatetime.unix_to_datetime(timezone)
    |> elem(1)
    |> get_seconds_since_midnight()
  end

  @spec seconds_since_midnight_to_date_time(integer, Date.t(), Timex.Types.valid_timezone()) ::
          DateTime.t()
  def seconds_since_midnight_to_date_time(
        seconds_since_midnight,
        %Date{} = current_service_date,
        timezone \\ Application.get_env(:rtr, :time_zone)
      ) do
    {:ok, dt} =
      current_service_date
      |> service_date_pseudo_midnight_unix()
      |> Kernel.+(seconds_since_midnight)
      |> FastLocalDatetime.unix_to_datetime(timezone)

    dt
  end

  @doc """
  Returns the unix timestamp of "midnight" where midnight is
  defined according to the way GTFS handles it:
  > Time - Time in the HH:MM:SS format (H:MM:SS is also accepted). The time
  > is measured from "noon minus 12h" of the service day (effectively
  > midnight except for days on which daylight savings time changes occur).
  > For times occurring after midnight, enter the time as a value greater
  > than 24:00:00 in HH:MM:SS local time for the day on which the trip
  > schedule begins.
  """
  @spec service_date_pseudo_midnight_unix(Date.t()) :: pos_integer()
  def service_date_pseudo_midnight_unix(%Date{} = date) do
    {:ok, naive_noon} = NaiveDateTime.new(date, ~T[12:00:00])

    naive_noon
    |> in_rtr_tz()
    |> DateTime.to_unix()
    |> Kernel.-(12 * 60 * 60)
  end

  @spec get_service_date(DateTime.t()) :: Date.t()
  def get_service_date(%DateTime{} = current_time \\ local_now()) do
    date = DateTime.to_date(current_time)

    if current_time.hour < @service_date_hour_cutoff do
      Date.add(date, -1)
    else
      date
    end
  end

  @spec get_gtfs_state_init_date() :: Date.t()
  def get_gtfs_state_init_date do
    {m, f, a} = Application.get_env(:rtr, :gtfs_state_init_date)
    apply(m, f, a)
  end

  def get_service_date_static(date) do
    date
  end

  def parse_calendar_date(date) do
    date
    |> Timex.parse!("%Y%m%d", :strftime)
    |> Timex.to_date()
  end

  @spec gtfs_delta(DateTime.t(), integer) :: integer
  def gtfs_delta(time \\ local_now(), seconds_since_midnight) do
    seconds_from_midnight_to_now = get_seconds_since_midnight(time)
    seconds_since_midnight - seconds_from_midnight_to_now
  end

  @spec off_hours?(DateTime.t()) :: boolean
  def off_hours?(date_time) do
    time = DateTime.to_time(date_time)

    case {Time.compare(time, ~T[01:30:00]), Time.compare(time, ~T[05:15:00])} do
      {:gt, :lt} ->
        true

      _ ->
        false
    end
  end

  @spec ms_until_tomorrow_at_time(DateTime.t(), Time.t()) :: pos_integer()
  def ms_until_tomorrow_at_time(now \\ local_now(), tomorrow_time) do
    tomorrow_time =
      now
      |> DateTime.to_date()
      |> Date.add(1)
      |> NaiveDateTime.new(tomorrow_time)
      |> elem(1)
      |> naive_to_datetime(now.time_zone)

    DateTime.diff(tomorrow_time, now, :millisecond)
  end

  defp naive_to_datetime(naive_datetime, time_zone) do
    case DateTime.from_naive(naive_datetime, time_zone) do
      {:ok, dt} ->
        dt

      {:ambiguous, before_dt, _after_dt} ->
        Logger.warning(
          "event=in_rtr_tz_ambiguous_dt ambiguous date time #{inspect(naive_datetime)}"
        )

        before_dt

      {:gap, _before_dt, after_dt} ->
        Logger.warning("event=in_rtr_tz_gap gap datetime #{inspect(naive_datetime)}")
        after_dt
    end
  end

  @spec format_gtfs_time_segment(number()) :: String.t()
  defp format_gtfs_time_segment(number),
    do: number |> Integer.to_string() |> String.pad_leading(2, "0")

  @spec to_gtfs_time(number() | nil, number()) :: nil | String.t()
  def to_gtfs_time(nil, _), do: nil

  def to_gtfs_time(time, current_time) do
    with {:ok, current_dt} <-
           FastLocalDatetime.unix_to_datetime(current_time, Application.get_env(:rtr, :time_zone)),
         sd <- get_service_date(current_dt),
         dt <- seconds_since_midnight_to_date_time(time, sd, current_dt.time_zone),
         {:ok, dt} <- DateTime.shift_zone(dt, Application.get_env(:rtr, :time_zone)) do
      hour = if dt.hour < @service_date_hour_cutoff, do: dt.hour + 24, else: dt.hour

      "#{format_gtfs_time_segment(hour)}:#{format_gtfs_time_segment(dt.minute)}:#{format_gtfs_time_segment(dt.second)}"
    else
      _ -> nil
    end
  end

  @spec to_gtfs_time_no_wraparound(number(), number()) :: nil | String.t()
  def to_gtfs_time_no_wraparound(time, current_time) do
    with {:ok, current_dt} <-
           FastLocalDatetime.unix_to_datetime(current_time, Application.get_env(:rtr, :time_zone)),
         sd <- get_service_date(current_dt),
         dt <- seconds_since_midnight_to_date_time(time, sd, current_dt.time_zone),
         {:ok, dt} <- DateTime.shift_zone(dt, Application.get_env(:rtr, :time_zone)) do
      hour =
        if dt.day > sd.day or dt.year > sd.year or dt.month > sd.month,
          do: dt.hour + 24,
          else: dt.hour

      "#{format_gtfs_time_segment(hour)}:#{format_gtfs_time_segment(dt.minute)}:#{format_gtfs_time_segment(dt.second)}"
    else
      _ -> nil
    end
  end

  @spec maybe_to_unix(nil | DateTime.t()) :: nil | integer()
  def maybe_to_unix(nil), do: nil

  def maybe_to_unix(%DateTime{time_zone: time_zone} = dt) when not is_nil(time_zone),
    do: DateTime.to_unix(dt)

  def maybe_to_unix(dt),
    do: dt |> naive_to_datetime(Application.get_env(:rtr, :time_zone)) |> DateTime.to_unix()
end
