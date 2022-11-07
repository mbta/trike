defmodule ExAws.Request.Req do
  @moduledoc """
  Implementation of ExAws.Request.HttpClient which uses Req to make HTTP requests.
  """
  @behaviour ExAws.Request.HttpClient

  @default_opts [
    connect_options: [protocol: :http2]
  ]

  @impl ExAws.Request.HttpClient
  def request(method, url, body, headers, http_opts \\ []) do
    http_opts = Keyword.merge(@default_opts, http_opts)
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
