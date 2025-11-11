defmodule Taxi.Supervisor do
  @moduledoc """
  Supervisor dinámico que gestiona los procesos de viaje.
  """

  use DynamicSupervisor

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

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

  def contar_viajes_activos do
    DynamicSupervisor.count_children(__MODULE__)
    |> Map.get(:active, 0)
  end

  def init(_opts) do
    "👷 Supervisor de viajes iniciado"
    |> Util.mostrar_mensaje()

    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
