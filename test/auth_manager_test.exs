defmodule Taxi.AuthManagerTest do
  use ExUnit.Case
  alias Taxi.AuthManager

  describe "Autenticación de Usuarios" do
    test "conectar usuario nuevo lo registra automáticamente" do
      usuario = "test_user_#{:rand.uniform(100000)}"

      resultado = AuthManager.conectar(usuario, "password123", :cliente)

      # AuthManager.conectar puede retornar {:ok, sesion} o un mensaje
      case resultado do
        {:ok, sesion} when is_map(sesion) ->
          assert sesion.username == usuario
          assert sesion.rol == :cliente
        {:ok, _mensaje} ->
          # Si retorna mensaje, verificar que está conectado
          assert AuthManager.esta_conectado?(usuario)
        _ ->
          flunk("Formato de respuesta inesperado")
      end

      assert AuthManager.esta_conectado?(usuario)

      # Limpiar
      AuthManager.desconectar(usuario)
    end

    test "desconectar usuario activo" do
      usuario = "disconnect_#{:rand.uniform(100000)}"

      {:ok, _} = AuthManager.conectar(usuario, "pass123", :cliente)
      assert AuthManager.esta_conectado?(usuario)

      resultado = AuthManager.desconectar(usuario)

      # Puede retornar :ok o {:ok, mensaje}
      assert resultado == :ok or match?({:ok, _}, resultado)
      refute AuthManager.esta_conectado?(usuario)
    end

    test "verificar si usuario está conectado" do
      usuario = "check_#{:rand.uniform(100000)}"

      refute AuthManager.esta_conectado?(usuario)

      {:ok, _} = AuthManager.conectar(usuario, "pass123", :conductor)
      assert AuthManager.esta_conectado?(usuario)

      AuthManager.desconectar(usuario)
      refute AuthManager.esta_conectado?(usuario)
    end

    test "obtener sesión de usuario conectado" do
      usuario = "session_#{:rand.uniform(100000)}"

      {:ok, _} = AuthManager.conectar(usuario, "pass123", :cliente)

      sesion = AuthManager.obtener_sesion(usuario)

      assert sesion != nil
      assert sesion.username == usuario
      assert sesion.rol == :cliente

      # Limpiar
      AuthManager.desconectar(usuario)
    end

    test "obtener sesión de usuario no conectado devuelve nil" do
      sesion = AuthManager.obtener_sesion("usuario_inexistente_#{:rand.uniform(100000)}")
      assert sesion == nil
    end

    test "tipos de usuario válidos: cliente y conductor" do
      cliente = "cliente_#{:rand.uniform(100000)}"
      conductor = "conductor_#{:rand.uniform(100000)}"

      {:ok, _} = AuthManager.conectar(cliente, "pass", :cliente)
      {:ok, _} = AuthManager.conectar(conductor, "pass", :conductor)

      sesion_cliente = AuthManager.obtener_sesion(cliente)
      sesion_conductor = AuthManager.obtener_sesion(conductor)

      assert sesion_cliente.rol == :cliente
      assert sesion_conductor.rol == :conductor

      # Limpiar
      AuthManager.desconectar(cliente)
      AuthManager.desconectar(conductor)
    end
  end
end
