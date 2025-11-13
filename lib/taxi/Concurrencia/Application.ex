defmodule Taxi.Application do
  @moduledoc """
  Módulo principal de arranque de la aplicación UrbanFleet.
  Responsabilidades:
  - Construir y arrancar el árbol de supervisión OTP.
  - Iniciar módulos base: autenticación, servidor de viajes y supervisor dinámico.

  Representa el punto de entrada típico en aplicaciones Elixir.
  """

  use Application

  @doc """
  Arranca la aplicación creando el árbol de supervisión.
  Devuelve {:ok, pid_supervisor_principal}.
  """
  def start(_type, _args) do
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    |> Util.mostrar_mensaje()

    "  🚕 URBANFLEET - Sistema de Taxis"
    |> Util.mostrar_mensaje()

    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    |> Util.mostrar_mensaje()

    children = [
      Taxi.AuthManager,
      Taxi.Server,
      Taxi.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Taxi.MainSupervisor]

    Supervisor.start_link(children, opts)
  end
end
