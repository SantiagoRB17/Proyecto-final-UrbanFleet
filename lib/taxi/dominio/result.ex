defmodule Taxi.Result do
  @moduledoc """
  Representa el resultado de un viaje completado o cancelado.
  """

  defstruct [
    :date,          # fecha y hora del evento
    :client,        # nombre del cliente
    :driver,        # nombre del conductor
    :origin,        # punto de partida
    :destination,   # punto de llegada
    :status         # :completed | :cancelled | :expired
  ]
end
