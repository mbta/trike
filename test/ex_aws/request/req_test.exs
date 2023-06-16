defmodule ExAws.Request.ReqTest do
  @moduledoc false
  use ExUnit.Case, async: true

  import ExAws.Request.Req

  describe "request/5" do
    test "does not follow redirects by default" do
      {:ok, result} = request(:get, "http://www.mbta.com/", "", [])

      assert %{status_code: 301} = result
    end

    test "follow_redirect: true will go to the next page" do
      {:ok, result} = request(:get, "http://www.mbta.com/", "", [], follow_redirect: true)

      assert %{status_code: 200} = result
    end
  end
end
