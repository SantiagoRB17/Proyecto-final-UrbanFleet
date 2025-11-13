defmodule Taxi.PersistenciaTest do
  use ExUnit.Case
  alias Taxi.{UserPersistence, LocationPersistence, TripPersistence, Trip}

  test "cargar usuarios desde JSON" do
    usuarios = UserPersistence.load_all()
    assert is_list(usuarios)
  end

  test "cargar ubicaciones desde JSON" do
    ubicaciones = LocationPersistence.load_all()
    assert is_list(ubicaciones)
    assert length(ubicaciones) > 0
  end

  test "buscar ubicación por nombre" do
    ubicacion = LocationPersistence.find_by_name("Parque")
    assert ubicacion != nil
    assert ubicacion.name == "Parque"
  end

  test "verificar si ubicación existe" do
    assert LocationPersistence.existe?("Parque")
    refute LocationPersistence.existe?("Ubicacion_Inexistente")
  end

  test "registrar viaje en log" do
    viaje = %Trip{
      id: 1,
      fecha: Date.utc_today(),
      cliente: "cliente1",
      conductor: "conductor1",
      origen: "Parque",
      destino: "Universidad",
      estado: :completado
    }

    # El sistema usa log_trip, no log_completed_trip
    assert :ok = TripPersistence.log_trip(viaje)
  end
end
