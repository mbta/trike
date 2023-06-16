defmodule ExAws.Request.Req do
  @moduledoc """
  Implementation of ExAws.Request.HttpClient which uses Req to make HTTP requests.
  """
  @behaviour ExAws.Request.HttpClient

  @default_opts [
    raw: true
  ]

  @impl ExAws.Request.HttpClient
  def request(method, url, body, headers, http_opts \\ []) do
    # ex_aws/lib/ex_aws/instance_meta.ex uses the `follow_redirect` keyword, but
    # with Req it's `follow_redirects`
    {follow_redirect, http_opts} = Keyword.pop(http_opts, :follow_redirect, false)

    http_opts =
      @default_opts
      |> Keyword.merge(http_opts)
      |> Keyword.put(:follow_redirects, follow_redirect)

    req = Req.new(http_opts)

    case Req.request(req,
           method: method,
           url: url,
           headers: headers,
           body: body
         ) do
      {:ok, resp} ->
        {:ok, %{status_code: resp.status, body: resp.body, headers: resp.headers}}

      {:error, e} ->
        {:error, e}
    end
  end
end
