defmodule Taxi.LocationManagerTest do
  use ExUnit.Case
  alias Taxi.LocationManager

  describe "Gestión de Ubicaciones" do
    test "listar nombres devuelve lista de ubicaciones" do
      ubicaciones = LocationManager.listar_nombres()

      assert is_list(ubicaciones)
      assert length(ubicaciones) > 0
    end

    test "ubicaciones conocidas son válidas" do
      assert LocationManager.ubicacion_valida?("Parque")
      assert LocationManager.ubicacion_valida?("Centro")
      assert LocationManager.ubicacion_valida?("Terminal")
      assert LocationManager.ubicacion_valida?("Universidad")
      assert LocationManager.ubicacion_valida?("Estadio")
    end

    test "ubicación desconocida no es válida" do
      refute LocationManager.ubicacion_valida?("Ubicacion_Inexistente")
      refute LocationManager.ubicacion_valida?("")
      refute LocationManager.ubicacion_valida?(nil)
    end

    test "mostrar ubicaciones no falla" do
      assert :ok = LocationManager.mostrar_ubicaciones()
    end
  end
end
