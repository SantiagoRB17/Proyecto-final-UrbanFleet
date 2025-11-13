defmodule Taxi.UserManager do
  @moduledoc """
  Módulo de servicio para la gestión básica de usuarios.
  """

  alias Taxi.{User, UserPersistence}

  @doc """
  Inicia un flujo interactivo por consola para registrar un nuevo usuario.
  Solicita nombre, contraseña y rol; luego persiste el usuario creado.
  Muestra un mensaje de confirmación al finalizar.
  """
  def registrar_usuario() do
    nombre = "Ingrese su nombre: "
    |> Util.ingresar(:texto)
    password = "Ingrese su contraseña: "
    |> Util.ingresar(:texto)
    rol = "Ingrese su rol (1-Cliente, 2-Conductor): "
    |> ingresar_rol()
    crear(nombre,password,rol)
    |> UserPersistence.save()
    Util.mostrar_mensaje("Usuario registrado exitosamente.")
  end

  @doc """
  Crea un struct `%User{}` con puntaje inicial en 0.
  No realiza persistencia; devuelve el valor para ser almacenado por el llamador.
  """
  def crear(nombre,password,rol) do
    %User{nombre: nombre,password: password, rol: rol, puntaje: 0}
  end

  @doc """
  Solicita y valida el rol del usuario a partir de un mensaje.
  Acepta "1" para :cliente y "2" para :conductor, repitiendo en caso de error.
  Devuelve el rol como átomo.
  """
  def ingresar_rol(mensaje) do
    rol = IO.gets(mensaje) |> String.trim()
    case rol do
      "1" -> :cliente
      "2" -> :conductor
      _ -> ingresar_rol("Ingrese un numero valido(1-Cliente,2-Conductor): ")
    end
  end

  @doc """
  Consulta el puntaje de un usuario por nombre.
  Retorna {:ok, puntaje} si existe o {:error, "Usuario no encontrado"} si no está registrado.
  """
  def consultarPuntaje() do
    nombre = IO.gets("Ingrese su nombre: ") |> String.trim()
    case UserPersistence.find_by_name(nombre) do
      nil -> {:error, "Usuario no encontrado"}
      %User{puntaje: puntaje} -> {:ok, puntaje}
    end
  end
end
