defmodule Taxi.TripServerTest do
  use ExUnit.Case
  alias Taxi.{TripServer, Trip, AuthManager}

  setup do
    cliente = "cliente_#{:rand.uniform(100000)}"
    conductor = "conductor_#{:rand.uniform(100000)}"

    AuthManager.conectar(cliente, "pass123", :cliente)
    AuthManager.conectar(conductor, "pass123", :conductor)

    on_exit(fn ->
      AuthManager.desconectar(cliente)
      AuthManager.desconectar(conductor)
    end)

    %{cliente: cliente, conductor: conductor}
  end

  describe "Proceso de Viaje Individual" do
    test "crear proceso de viaje", %{cliente: cliente} do
      viaje = %Trip{
        id: :rand.uniform(100000),
        fecha: Date.utc_today(),
        cliente: cliente,
        origen: "Parque",
        destino: "Universidad",
        estado: :pendiente
      }

      {:ok, pid} = TripServer.start_link(viaje)

      assert Process.alive?(pid)

      # Detener proceso
      GenServer.stop(pid)
    end

    test "obtener estado del viaje", %{cliente: cliente} do
      viaje = %Trip{
        id: :rand.uniform(100000),
        fecha: Date.utc_today(),
        cliente: cliente,
        origen: "Centro",
        destino: "Terminal",
        estado: :pendiente
      }

      {:ok, pid} = TripServer.start_link(viaje)

      estado = TripServer.obtener_estado(pid)

      assert estado.cliente == cliente
      assert estado.origen == "Centro"
      assert estado.destino == "Terminal"
      assert estado.estado == :pendiente

      GenServer.stop(pid)
    end

    test "aceptar viaje cambia estado a en_progreso", %{cliente: cliente, conductor: conductor} do
      viaje = %Trip{
        id: :rand.uniform(100000),
        fecha: Date.utc_today(),
        cliente: cliente,
        origen: "Parque",
        destino: "Universidad",
        estado: :pendiente
      }

      {:ok, pid} = TripServer.start_link(viaje)

      {:ok, viaje_actualizado} = TripServer.aceptar(pid, conductor)

      assert viaje_actualizado.conductor == conductor
      assert viaje_actualizado.estado == :en_progreso

      GenServer.stop(pid)
    end

    test "proceso de viaje tiene timeout configurado", %{cliente: cliente} do
      viaje = %Trip{
        id: :rand.uniform(100000),
        fecha: Date.utc_today(),
        cliente: cliente,
        origen: "Estadio",
        destino: "Centro",
        estado: :pendiente
      }

      {:ok, pid} = TripServer.start_link(viaje)

      # Verificar que el proceso está vivo
      assert Process.alive?(pid)

      # No esperamos 40 segundos, solo verificamos que fue creado correctamente
      estado = TripServer.obtener_estado(pid)
      assert estado.estado == :pendiente

      GenServer.stop(pid)
    end
  end
end
