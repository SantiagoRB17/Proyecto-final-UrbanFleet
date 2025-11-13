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
        "✅ Viaje #{datos.id} bajo supervisión"
        |> Util.mostrar_mensaje()
        {:ok, pid}

      error ->
        "❌ Error al iniciar viaje: #{inspect(error)}"
        |> Util.mostrar_error()
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
  Inicializa el supervisor dinámico con estrategia :one_for_one.
  Se muestra un mensaje informativo al arrancar.
  """
  def init(_opts) do
    "👷 Supervisor de viajes iniciado"
    |> Util.mostrar_mensaje()

    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
