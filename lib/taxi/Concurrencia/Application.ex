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
    mostrar_banner_inicio()

    children = [
      Taxi.AuthManager,
      Taxi.Server,
      Taxi.Supervisor
    ]

    opts = [strategy: :one_for_one, name: Taxi.MainSupervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        mostrar_inicio_exitoso()
        {:ok, pid}
      error ->
        mostrar_error_inicio(error)
        error
    end
  end

  # === Funciones de Visualización ===

  defp mostrar_banner_inicio do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════════════════════╗")
    Util.mostrar_mensaje("║                                                       ║")
    Util.mostrar_mensaje("║          🚕  URBANFLEET - Sistema de Taxis  🚕        ║")
    Util.mostrar_mensaje("║                                                       ║")
    Util.mostrar_mensaje("║           Sistema Distribuido de Transporte          ║")
    Util.mostrar_mensaje("║                                                       ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════════════════════╝")
    Util.mostrar_mensaje("\n┌───────────────────────────────────────────────────────┐")
    Util.mostrar_mensaje("│  🔄 Iniciando componentes del sistema...             │")
    Util.mostrar_mensaje("└───────────────────────────────────────────────────────┘\n")
  end

  defp mostrar_inicio_exitoso do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════════════════════╗")
    Util.mostrar_mensaje("║  ✅ Sistema iniciado correctamente                    ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════════════════════╝")
    Util.mostrar_mensaje("\n💡 Usa Taxi.CLI.iniciar() para comenzar\n")
  end

  defp mostrar_error_inicio(error) do
    Util.mostrar_mensaje("\n╔═══════════════════════════════════════════════════════╗")
    Util.mostrar_mensaje("║  ❌ Error al iniciar el sistema                       ║")
    Util.mostrar_mensaje("╚═══════════════════════════════════════════════════════╝")
    Util.mostrar_error("\n#{inspect(error)}\n")
  end
end
