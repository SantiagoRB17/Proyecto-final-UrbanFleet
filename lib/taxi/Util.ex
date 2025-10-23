defmodule Util do
  @moduledoc """
  Módulo con funciones que se reutilizan
  - autor: Nombre del autor.
  - fecha: Fecha de creación.
  - licencia: GNU GLP v3
  """

  @doc """
  Función para mostrar un mensaje en la pantalla.
  ## Parámetros
    - mensaje: texto que se le presenta al usuario.
  ## Ejemplo
    iex> Util.mostrar_mensaje("Hola, mundo!")
    o puede usar
    "Hola mundo"
    |> Util.mostrar_mensaje()
  """
  def mostrar_mensaje(mensaje) do
    mensaje
    |> IO.puts()
  end
  
  def ingresar(mensaje, :texto) do
    mensaje
    |> IO.gets()
    |> String.trim()
  end

  def ingresar(mensaje, :entero) do
    try do
      mensaje
      |> ingresar(:texto)
      |> String.to_integer()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un número entero\n"
        |> mostrar_error()

        mensaje
        |> ingresar(:entero)
    end
  end

  def ingresar(mensaje, :real) do
    try do
      mensaje
      |> ingresar(:texto)
      |> String.to_float()
    rescue
      ArgumentError ->
        "Error, se espera que ingrese un número real\n"
        |> mostrar_error()

        mensaje
        |> ingresar(:real)
    end
  end

  def ingresar(mensaje, :boolean) do
    valor =
      mensaje
      |> ingresar(:texto)
      |> String.downcase()

    Enum.member?(["si", "sí", "s"], valor)
  end

  def mostrar_error(mensaje) do
    IO.puts(:standard_error, mensaje)
  end
end
