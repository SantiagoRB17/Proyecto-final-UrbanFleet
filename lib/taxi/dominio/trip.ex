defmodule Taxi.Trip do
  @moduledoc """
  Estructura de dominio que representa un viaje dentro del sistema.

  Campos:
  - id: identificador numérico único del viaje.
  - fecha: fecha en la que se creó el viaje (Date).
  - cliente: nombre del cliente que solicita el viaje.
  - conductor: nombre del conductor asignado (o nil si no fue aceptado).
  - origen: ubicación inicial del recorrido.
  - destino: ubicación final del recorrido.
  - estado: ciclo de vida del viaje, uno de:
    :pendiente | :en_progreso | :completado | :expirado
  """

  defstruct [
    :id,
    :fecha,
    :cliente,
    :conductor,
    :origen,
    :destino,
    :estado
  ]
end
