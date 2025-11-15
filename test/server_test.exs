defmodule Taxi.ServerTest do
  use ExUnit.Case
  alias Taxi.{Server, AuthManager}

  setup do
    # Generar nombres únicos para evitar conflictos
    cliente = "cliente_#{:rand.uniform(100000)}"
    conductor = "conductor_#{:rand.uniform(100000)}"

    # Conectar usuarios (auto-registro)
    {:ok, sesion_cliente} = AuthManager.conectar(cliente, "pass123", :cliente)
    {:ok, sesion_conductor} = AuthManager.conectar(conductor, "pass123", :conductor)

    on_exit(fn ->
      AuthManager.desconectar(cliente)
      AuthManager.desconectar(conductor)
    end)

    %{
      cliente: cliente,
      conductor: conductor,
      sesion_cliente: sesion_cliente,
      sesion_conductor: sesion_conductor
    }
  end

  describe "Gestión de Viajes" do
    test "solicitar viaje desde ubicación válida", %{cliente: cliente} do
      origen = "Parque"
      destino = "Universidad"

      resultado = Server.solicitar_viaje(cliente, origen, destino)

      assert {:ok, viaje} = resultado
      assert viaje.cliente == cliente
      assert viaje.origen == origen
      assert viaje.destino == destino
      assert viaje.estado == :pendiente
    end

    test "conductor acepta viaje disponible", %{cliente: cliente, conductor: conductor} do
      # Cliente solicita viaje
      {:ok, viaje} = Server.solicitar_viaje(cliente, "Parque", "Universidad")
      trip_id = viaje.id

      # Conductor acepta viaje
      resultado = Server.aceptar_viaje(trip_id, conductor)

      assert {:ok, viaje_aceptado} = resultado
      assert viaje_aceptado.conductor == conductor
      assert viaje_aceptado.estado == :en_progreso
    end

    test "listar viajes disponibles muestra viajes pendientes", %{cliente: cliente} do
      # Solicitar un viaje
      {:ok, _viaje} = Server.solicitar_viaje(cliente, "Centro", "Terminal")

      # Esperar a que se procese
      Process.sleep(100)

      # Listar viajes
      viajes = Server.listar_viajes_disponibles()

      assert is_list(viajes)
      assert length(viajes) > 0
      assert Enum.any?(viajes, fn v -> v.cliente == cliente end)
    end

    test "múltiples viajes pueden estar disponibles simultáneamente" do
      cliente1 = "multi1_#{:rand.uniform(100000)}"
      cliente2 = "multi2_#{:rand.uniform(100000)}"

      AuthManager.conectar(cliente1, "pass123", :cliente)
      AuthManager.conectar(cliente2, "pass123", :cliente)

      {:ok, _} = Server.solicitar_viaje(cliente1, "Parque", "Universidad")
      {:ok, _} = Server.solicitar_viaje(cliente2, "Centro", "Terminal")

      Process.sleep(100)

      viajes = Server.listar_viajes_disponibles()
      assert length(viajes) >= 2

      AuthManager.desconectar(cliente1)
      AuthManager.desconectar(cliente2)
    end
  end
end
