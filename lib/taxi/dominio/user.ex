defmodule Taxi.User do
  @moduledoc """
  Módulo que representa a un usuario en el sistema de taxi.
  """
  defstruct [
    # Identificador único del usuario
    :username,
    # Contraseña simple
    :password,
    # "cliente" o "conductor"
    :role,
    # Puntaje acumulado
    score: 0
  ]
end
