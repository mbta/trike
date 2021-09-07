defmodule Fakes.FakeDateTime do
  @moduledoc """
  A DateTime fake that always returns the same DateTime.
  """

  @spec utc_now :: DateTime.t()
  def utc_now do
    DateTime.new!(Date.new!(2021, 8, 13), Time.new!(12, 0, 0), "Etc/UTC")
  end
end
