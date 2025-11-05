defmodule Taxi.TripManager do

  alias Taxi.TripPersistence

  def estado do
    %{trips: %{}, next_id: 1}
  end

  def crear_viaje(%{trips: trips, next_id: id} = estado, cliente, origen, destino) do
    trip = %{
      id: id,
      client: cliente,
      driver: nil,
      origin: origen,
      destination: destino,
      status: :pendiente
    }

    nuevo_viaje = Map.put(trips, id, trip)
    actualizado = %{estado | trips: nuevo_viaje, next_id: id + 1}

    {trip, actualizado}
  end

  def listar_viajes_disponibles(estado) do
    estado.trips
    |> Map.values()
    |> Enum.filter(&(&1.estado == :pendiente))
  end

  def buscar_viaje(estado, trip_id) do
    case Map.get(estado.trips, trip_id) do
      nil -> {:error, "Viaje no encontrado"}
      trip -> {:ok, trip}
    end
  end

  def aceptar_viaje(estado, trip_id, conductor) do
    case buscar_viaje(estado, trip_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, trip} ->
        if trip.estado == :pendiente do
          trip_actualizado = %{trip |
            conductor: conductor,
            estado: :en_progreso
          }

          nuevo_estado = %{estado |
            trips: Map.put(estado.trips, trip_id, trip_actualizado)
          }

          {:ok, nuevo_estado}
        else
          {:error, "El viaje no está disponible"}
        end
    end
  end

  def completar_viaje(estado, trip_id) do
    case buscar_viaje(estado, trip_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, trip} ->
        if trip.estado == :en_progreso do
          trip_completado = %{trip | estado: :completado}

          TripPersistence.log_completed_trip(trip_completado)

          nuevo_estado = %{estado |
            trips: Map.put(estado.trips, trip_id, trip_completado)
          }

          {:ok, trip_completado, nuevo_estado}
        else
          {:error, "El viaje no está en progreso"}
        end
    end
  end

  def expirar_viaje(estado, trip_id) do
    case buscar_viaje(estado, trip_id) do
      {:error, mensaje} ->
        {:error, mensaje}

      {:ok, trip} ->
        if trip.estado == :pendiente do
          trip_expirado = %{trip | estado: :expirado}

          nuevo_estado = %{estado |
            trips: Map.put(estado.trips, trip_id, trip_expirado)
          }

          {:ok, trip_expirado, nuevo_estado}
        else
          {:error, "El viaje ya no está pendiente"}
        end
    end
  end

  def listar_viajes_cliente(estado, cliente) do
    estado.trips
    |> Map.values()
    |> Enum.filter(&(&1.cliente == cliente))
  end

  def listar_viajes_conductor(estado, conductor) do
    estado.trips
    |> Map.values()
    |> Enum.filter(&(&1.conductor == conductor))
  end

   def contar_viajes_completados(estado, nombre, :cliente) do
    estado.trips
    |> Map.values()
    |> Enum.filter(&(&1.cliente == nombre && &1.estado == :completado))
    |> length()
  end

  def contar_viajes_completados(estado, nombre, :conductor) do
    estado.trips
    |> Map.values()
    |> Enum.filter(&(&1.conductor == nombre && &1.estado == :completado))
    |> length()
  end

end
