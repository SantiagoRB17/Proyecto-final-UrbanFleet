defmodule Taxi.LocationPersistence do

  alias Taxi.{Location, Persistence}

  @locations_file "data/locations.json"

  def load_all do
    Persistence.read_json(@locations_file, Location)
  end

  def find_by_name(nombre) do
    load_all()
    |> Enum.find(&(&1.name == nombre))
  end
  def existe?(nombre) do
    case find_by_name(nombre) do
      nil -> false
      _ -> true
    end
  end


end
