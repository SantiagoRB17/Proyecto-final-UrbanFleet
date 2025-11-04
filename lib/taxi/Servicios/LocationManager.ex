defmodule Taxi.LocationManager do

  alias Taxi.Location

  @locations_file "data/locations.json"

  def cargar_ubicaciones do
    case File.read(@locations_file) do
      {:ok, content} ->
        Jason.decode!(content)
        |> Enum.map(&crear_location/1)

      {:error, _} ->
        []
    end
  end

  def crear_location(nombre) when is_binary(nombre) do
    %Location{name: nombre}
  end

  def ubicacion_valida?(nombre) do
    cargar_ubicaciones()
    |> Enum.any?(&(&1.name == nombre))
  end

  def mostrar_ubicaciones do
    Util.mostrar_mensaje("\n=== UBICACIONES DISPONIBLES ===")

    listar_nombres()
    |> Enum.with_index(1)
    |> Enum.each(fn {ubicacion, indice} ->
      Util.mostrar_mensaje("#{indice}. #{ubicacion}")
    end)
  end

  def listar_nombres do
    cargar_ubicaciones()
    |> Enum.map(&(&1.name))
  end

  def solicitar_ubicacion(mensaje) do
    mostrar_ubicaciones()
    ubicacion = Util.ingresar(mensaje, :texto)

    if ubicacion_valida?(ubicacion) do
      ubicacion
    else
      Util.mostrar_error("Ubicación no válida. Por favor, seleccione una ubicación de la lista.")
      solicitar_ubicacion(mensaje)
    end
  end

  def solicitar_origen_destino do
    origen = solicitar_ubicacion("\nIngrese la ubicación de origen: ")
    destino = solicitar_ubicacion("Ingrese la ubicación de destino: ")

    if origen == destino do
      Util.mostrar_error("El origen y destino no pueden ser iguales.")
      solicitar_origen_destino()
    else
      {origen, destino}
    end
  end

  def buscar_ubicacion(nombre) do
    case Enum.find(cargar_ubicaciones(), &(&1.name == nombre)) do
      nil -> {:error, "Ubicación no encontrada"}
      location -> {:ok, location}
    end
  end

  def validar_origen_destino(origen, destino) do
    cond do
      !ubicacion_valida?(origen) ->
        {:error, "El origen '#{origen}' no es una ubicación válida"}

      !ubicacion_valida?(destino) ->
        {:error, "El destino '#{destino}' no es una ubicación válida"}

      origen == destino ->
        {:error, "El origen y destino no pueden ser iguales"}

      true ->
        :ok
    end
  end

end
