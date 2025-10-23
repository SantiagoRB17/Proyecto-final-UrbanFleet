defmodule Taxi.User do
  @moduledoc """
  Módulo que representa a un usuario en el sistema de taxi.
  """
  defstruct [
    # Identificador único del usuario
    :nombre,
    # Contraseña simple
    :password,
    # "cliente" o "conductor"
    :rol,
    # Puntaje acumulado
    :puntaje
  ]
end
