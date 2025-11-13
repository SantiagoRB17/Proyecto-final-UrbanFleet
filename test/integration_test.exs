defmodule Taxi.IntegrationTest do
  use ExUnit.Case
  alias Taxi.{Server, AuthManager}

  test "flujo completo de viaje" do
    # Generar nombres únicos
    cliente = "cliente_#{:rand.uniform(100000)}"
    conductor = "conductor_#{:rand.uniform(100000)}"

    # Conectar usuarios (registra automáticamente)
    {:ok, _} = AuthManager.conectar(cliente, "pass123", :cliente)
    {:ok, _} = AuthManager.conectar(conductor, "pass123", :conductor)

    # Cliente solicita viaje - API devuelve {:ok, %Trip{}} directamente
    {:ok, viaje} = Server.solicitar_viaje(cliente, "Parque", "Universidad")
    assert viaje.estado == :pendiente
    assert viaje.cliente == cliente

    # Conductor ve viajes disponibles
    Process.sleep(200)
    viajes_disponibles = Server.listar_viajes_disponibles()
    assert length(viajes_disponibles) > 0

    # Conductor acepta viaje - orden correcto: aceptar_viaje(trip_id, conductor)
    {:ok, viaje_aceptado} = Server.aceptar_viaje(viaje.id, conductor)
    assert viaje_aceptado.estado == :en_progreso
    assert viaje_aceptado.conductor == conductor
  end

  test "múltiples usuarios simultáneos" do
    # Crear 2 clientes
    cliente1 = "cliente_#{:rand.uniform(100000)}"
    cliente2 = "cliente_#{:rand.uniform(100000)}"

    AuthManager.conectar(cliente1, "pass123", :cliente)
    AuthManager.conectar(cliente2, "pass123", :cliente)

    # Ambos solicitan viajes
    {:ok, _} = Server.solicitar_viaje(cliente1, "Parque", "Universidad")
    {:ok, _} = Server.solicitar_viaje(cliente2, "Centro", "Terminal")

    # Verificar que hay viajes disponibles
    Process.sleep(200)
    viajes = Server.listar_viajes_disponibles()
    assert length(viajes) >= 2
  end
end
