defmodule Taxi.RankingManager do
  
  alias Taxi.{User, UserPersistence}

  def actualizar_puntaje(nombre, puntos) do
    usuarios = UserPersistence.load_all()

    case Enum.find_index(usuarios, &(&1.nombre == nombre)) do
      nil ->
        {:error, "Usuario no encontrado"}

      indice ->
        usuario = Enum.at(usuarios, indice)
        nuevo_puntaje = usuario.puntaje + puntos
        usuario_actualizado = %{usuario | puntaje: nuevo_puntaje}

        usuarios_actualizados = List.replace_at(usuarios, indice, usuario_actualizado)
        UserPersistence.save_all(usuarios_actualizados)

        {:ok, usuario_actualizado}
    end
  end

  def otorgar_puntos_viaje_completado(cliente, conductor) do
    actualizar_puntaje(cliente, 10)
    actualizar_puntaje(conductor, 15)
    :ok
  end

  def penalizar_viaje_expirado(cliente) do
    actualizar_puntaje(cliente, -5)
  end

  def obtener_ranking_global do
    UserPersistence.load_all()
    |> Enum.sort_by(&(&1.puntaje), :desc)
  end

  def obtener_ranking_conductores do
    UserPersistence.load_all()
    |> Enum.filter(&(&1.rol == :conductor))
    |> Enum.sort_by(&(&1.puntaje), :desc)
  end

  def obtener_ranking_clientes do
    UserPersistence.load_all()
    |> Enum.filter(&(&1.rol == :cliente))
    |> Enum.sort_by(&(&1.puntaje), :desc)
  end

  def obtener_top(n \\ 10) do
    obtener_ranking_global()
    |> Enum.take(n)
  end

  def obtener_top_conductores(n \\ 10) do
    obtener_ranking_conductores()
    |> Enum.take(n)
  end

  def obtener_top_clientes(n \\ 10) do
    obtener_ranking_clientes()
    |> Enum.take(n)
  end

  def mostrar_ranking_global do
    Util.mostrar_mensaje("\n=== RANKING GLOBAL ===")

    obtener_ranking_global()
    |> Enum.with_index(1)
    |> Enum.each(fn {usuario, posicion} ->
      rol_texto = if usuario.rol == :conductor, do: "Conductor", else: "Cliente"
      Util.mostrar_mensaje("#{posicion}. #{usuario.nombre} (#{rol_texto}) - #{usuario.puntaje} pts")
    end)
  end

  def mostrar_ranking_conductores do
    Util.mostrar_mensaje("\n=== TOP CONDUCTORES ===")

    obtener_ranking_conductores()
    |> Enum.with_index(1)
    |> Enum.each(fn {conductor, posicion} ->
      Util.mostrar_mensaje("#{posicion}. #{conductor.nombre} - #{conductor.puntaje} pts")
    end)
  end

  def mostrar_ranking_clientes do
    Util.mostrar_mensaje("\n=== TOP CLIENTES ===")

    obtener_ranking_clientes()
    |> Enum.with_index(1)
    |> Enum.each(fn {cliente, posicion} ->
      Util.mostrar_mensaje("#{posicion}. #{cliente.nombre} - #{cliente.puntaje} pts")
    end)
  end

  def obtener_posicion(nombre) do
    ranking = obtener_ranking_global()

    case Enum.find_index(ranking, &(&1.nombre == nombre)) do
      nil -> {:error, "Usuario no encontrado en el ranking"}
      indice -> {:ok, indice + 1}
    end
  end

   def consultar_puntaje(nombre) do
    case UserPersistence.find_by_name(nombre) do
      nil ->
        Util.mostrar_mensaje("Usuario no encontrado")

      usuario ->
        rol_texto = if usuario.rol == :conductor, do: "Conductor", else: "Cliente"
        Util.mostrar_mensaje("\n=== TU PUNTAJE ===")
        Util.mostrar_mensaje("Nombre: #{usuario.nombre}")
        Util.mostrar_mensaje("Rol: #{rol_texto}")
        Util.mostrar_mensaje("Puntaje: #{usuario.puntaje} pts")

        case obtener_posicion(nombre) do
          {:ok, posicion} -> Util.mostrar_mensaje("Posición en ranking: ##{posicion}")
          _ -> :ok
        end
    end
  end

end
