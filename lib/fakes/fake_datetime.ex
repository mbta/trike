defmodule Fakes.FakeDateTime do
  @moduledoc """
  A DateTime fake that always returns the same DateTime.
  """

  @spec utc_now :: DateTime.t()
  def utc_now, do: ~U[2021-08-13 12:00:00Z]
end
