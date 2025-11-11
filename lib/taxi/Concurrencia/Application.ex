defmodule Taxi.Application do
  @moduledoc """
  Módulo principal de la aplicación UrbanFleet.
  Inicia el árbol de supervisión OTP.
  """

  use Application

  def start(_type, _args) do
    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    |> Util.mostrar_mensaje()

    "  🚕 URBANFLEET - Sistema de Taxis"
    |> Util.mostrar_mensaje()

    "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    |> Util.mostrar_mensaje()

    children = [
      Taxi.AuthManager,   # Gestión de sesiones
      Taxi.Server,        # Servidor principal (como nodo-servidor en Problema 19)
      Taxi.Supervisor     # Supervisor de viajes
    ]

    opts = [strategy: :one_for_one, name: Taxi.MainSupervisor]

    Supervisor.start_link(children, opts)
  end
end
