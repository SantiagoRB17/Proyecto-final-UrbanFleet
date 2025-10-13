defmodule Taxi.Trip do
  defstruct [
    :id,           # Identificador único del viaje
    :client,       # nombre del cliente (string)
    :driver,       # nombre del conductor (string o nil)
    :origin,       # ubicación inicial
    :destination,  # ubicación final
    :status,       # :pending | :in_progress | :completed | :expired
    :start_time,   # fecha/hora inicio (opcional)
    :end_time      # fecha/hora fin (opcional)
  ]
end
