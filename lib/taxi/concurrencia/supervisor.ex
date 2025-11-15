defmodule Taxi.Supervisor do
  @moduledoc """
  Supervisor dinámico encargado de gestionar procesos de viaje (Taxi.TripServer).
  Características:
  - Usa DynamicSupervisor para crear procesos bajo demanda.
  - Cada viaje se supervisa con estrategia :temporary (no se reinicia tras terminar).
  - Facilita control académico sobre concurrencia y aislamiento de fallos.
  """

  use DynamicSupervisor

  @doc """
  Inicia el supervisor dinámico y lo registra con su nombre de módulo.
  Debe ejecutarse dentro del árbol de la aplicación principal.
  """
  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Inicia un nuevo proceso de viaje bajo supervisión.
  Recibe los datos del viaje y construye la especificación mínima.
  Devuelve {:ok, pid} o {:error, razon}.
  """
  def iniciar_viaje(datos) do
    spec = %{
      id: Taxi.TripServer,
      start: {Taxi.TripServer, :start_link, [datos]},
      restart: :temporary
    }

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, pid} ->
        mostrar_viaje_supervisado(datos.id)
        {:ok, pid}

      error ->
        mostrar_error_supervision(datos.id, error)
        error
    end
  end

  @doc """
  Cuenta la cantidad de procesos activos (viajes en ejecución).
  Útil para monitoreo básico del sistema.
  """
  def contar_viajes_activos do
    DynamicSupervisor.count_children(__MODULE__)
    |> Map.get(:active, 0)
  end

  @doc """
  Muestra estadísticas del supervisor.
  """
  def mostrar_estadisticas do
    stats = DynamicSupervisor.count_children(__MODULE__)

    Util.mostrar_mensaje("\n┌─────────────────────────────────────┐")
    Util.mostrar_mensaje("│  📊 Estadísticas del Supervisor     │")
    Util.mostrar_mensaje("├─────────────────────────────────────┤")
    Util.mostrar_mensaje("│  Procesos activos: #{String.pad_trailing("#{stats.active}", 14)} │")
    Util.mostrar_mensaje("│  Procesos totales: #{String.pad_trailing("#{stats.workers}", 14)} │")
    Util.mostrar_mensaje("└─────────────────────────────────────┘")
  end

  @doc """
  Inicializa el supervisor dinámico con estrategia :one_for_one.
  Se muestra un mensaje informativo al arrancar.
  """
  def init(_opts) do
    mostrar_inicio()
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  # === Funciones de Visualización ===

  defp mostrar_inicio do
    Util.mostrar_mensaje("   👷 Supervisor de viajes iniciado")
  end

  defp mostrar_viaje_supervisado(id) do
    Util.mostrar_mensaje("      ├─ ✅ Viaje #{id} bajo supervisión")
  end

  defp mostrar_error_supervision(id, error) do
    Util.mostrar_error("      ├─ ❌ Error al supervisar viaje #{id}")
    Util.mostrar_error("      └─ Detalle: #{inspect(error)}")
  end
end
