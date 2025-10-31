defmodule Taxi.TripManager do

  def estado do
    %{trips: {}, next_id: 1}
  end

  def crear_viaje(estado, cliente, origen, destino) do
    id = estado.next_id

    trip = %{
      id: id,
      client: cliente,
      driver: nil,
      origin: origen,
      destination: destino,
      status: :pendiente
    }

    nuevo_viaje = Map.put(estado.trips, id, trip)
    actualizado = %{estado | trips: nuevo_viaje, next_id: id + 1}

    {trip, actualizado}
  end

  def listar_viajes_disponibles(estado) do
    estado.trips
    |> Map.values()
    |> Enum.filter(&(&1.estado == :pendiente))
  end


end
