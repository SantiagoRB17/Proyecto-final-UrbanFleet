defmodule ProyectoFinalTest do
  use ExUnit.Case

  describe "Aplicación Taxi" do
    test "la aplicación inicia correctamente" do
      # Verificar que los procesos principales están vivos
      assert Process.whereis(Taxi.AuthManager) != nil
      assert Process.whereis(:taxi_server) != nil
    end

    test "supervisor está activo" do
      # Verificar que el supervisor de viajes está funcionando
      supervisor = Process.whereis(Taxi.Supervisor)
      assert supervisor != nil
      assert Process.alive?(supervisor)
    end
  end
end
