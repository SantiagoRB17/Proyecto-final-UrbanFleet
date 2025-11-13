defmodule Taxi.LocationPersistence do
  @moduledoc """
  Módulo de persistencia para ubicaciones.
  """

  alias Taxi.{Location, Persistence}

  @locations_file "data/locations.json"

  @doc """
  Carga todas las ubicaciones desde el archivo JSON.
  Si el archivo no existe, retorna una lista vacía.
  """
  def load_all do
    Persistence.read_json(@locations_file, Location)
  end

  @doc """
  Busca una ubicación por su nombre.
  Devuelve `%Location{}` si existe o `nil` si no se encuentra.
  """
  def find_by_name(nombre) do
    load_all()
    |> Enum.find(&(&1.name == nombre))
  end

  @doc """
  Indica si existe una ubicación con el nombre dado.
  Retorna true si se encuentra, false en caso contrario.
  """
  def existe?(nombre) do
    case find_by_name(nombre) do
      nil -> false
      _ -> true
    end
  end
end
