defmodule Taxi.LocationManager do
  @moduledoc """
  Servicio utilitario para manejar ubicaciones disponibles en el sistema.
  """

  alias Taxi.{Location, LocationPersistence}

  @doc """
  Construye una nueva ubicación a partir del nombre dado.
  No realiza persistencia; devuelve el struct para uso del llamador.
  """
  def crear_location(nombre) when is_binary(nombre) do
    %Location{name: nombre}
  end

  @doc """
  Verifica si el nombre corresponde a una ubicación persistida.
  Devuelve true o false según exista en el almacenamiento.
  """
  def ubicacion_valida?(nombre) do
    LocationPersistence.existe?(nombre)
  end

  @doc """
  Muestra por consola la lista de ubicaciones disponibles, con numeración.
  Pensado para orientar al usuario antes de solicitar una entrada.
  """
  def mostrar_ubicaciones do
    Util.mostrar_mensaje("\n=== UBICACIONES DISPONIBLES ===")

    listar_nombres()
    |> Enum.with_index(1)
    |> Enum.each(fn {ubicacion, indice} ->
      Util.mostrar_mensaje("#{indice}. #{ubicacion}")
    end)
  end

  @doc """
  Devuelve la lista de nombres de ubicaciones actualmente cargadas.
  """
  def listar_nombres do
    LocationPersistence.load_all()
    |> Enum.map(&(&1.name))
  end

  @doc """
  Solicita una ubicación al usuario mostrando previamente la lista disponible.
  Valida la entrada; si no es válida, vuelve a solicitarla.
  Devuelve el nombre de una ubicación existente.
  """
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

  @doc """
  Solicita al usuario el origen y el destino, validando que ambos existan y no sean iguales.
  Retorna una tupla {origen, destino} cuando la validación es exitosa.
  """
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

  @doc """
  Busca una ubicación por nombre y devuelve {:ok, %Location{}} si existe o {:error, mensaje} si no.
  Útil para flujos que requieran cargar el struct completo.
  """
  def buscar_ubicacion(nombre) do
    case LocationPersistence.find_by_name(nombre) do
      nil -> {:error, "Ubicación no encontrada"}
      location -> {:ok, location}
    end
  end

  @doc """
  Valida un par origen/destino. Retorna :ok si ambos existen y son distintos.
  En caso contrario, devuelve {:error, mensaje} describiendo el problema.
  """
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
