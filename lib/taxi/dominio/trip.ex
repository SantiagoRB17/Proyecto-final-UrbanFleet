defmodule Taxi.Trip do
  defstruct [
    :id,           # Identificador único del viaje
    :fecha,        # fecha
    :cliente,      # nombre del cliente (string)
    :conductor,    # nombre del conductor (string o nil)
    :origen,       # ubicación inicial
    :destino,      # ubicación final
    :estado,       # :pendiente | :en_progreso | :completado | :expirado
  ]
end
