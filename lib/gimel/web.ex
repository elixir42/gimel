defmodule Gimel.Web do
  @moduledoc """
  Gimel Web application
  """

  use Application

  def start(_type, _args) do
    children = [
      Plug.Cowboy.child_spec(
        scheme: :http,
        plug: Gimel.Router,
        options: [port: 4000]
      )
    ]

    opts = [strategy: :one_for_one, name: Gimel.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
