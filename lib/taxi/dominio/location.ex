defmodule Taxi.Location do
  @moduledoc """
  Estructura mínima para representar una ubicación dentro del sistema.

  Campos:
  - name: nombre o etiqueta legible de la ubicación (por ejemplo, "Parque Central").
  
  """

  defstruct [:name]
end
