defmodule Taxi.NodeHelper do
  @moduledoc """
  Módulo auxiliar para facilitar la conexión entre nodos en un entorno distribuido.
  """

  @cookie :urbanfleet_taxi

  @doc """
  Intenta conectar el nodo actual con otros nodos.
  - Sin argumentos: intenta conexiones automáticas a nombres predefinidos.
  - Con `nodo_remoto`: intenta conectarse únicamente al nodo especificado.
  Retorna :ok si conecta al menos a un nodo o :no_conectado/:error si no fue posible.
  """
  def conectar_nodos(nodo_remoto \\ nil) do
    # Configurar cookie si no está configurada
    configurar_cookie()

    case nodo_remoto do
      nil -> conectar_automatico()
      nodo -> conectar_especifico(nodo)
    end
  end

  @doc """
  Muestra información sobre el nodo actual y la lista de nodos conectados.
  Emite consejos en caso de no existir conexiones activas.
  """
  def info_nodos do
    Util.mostrar_mensaje("\n=== INFORMACIÓN DE NODOS ===")
    Util.mostrar_mensaje("Nodo actual: #{node()}")

    nodos_conectados = Node.list()
    if Enum.empty?(nodos_conectados) do
      Util.mostrar_mensaje("Nodos conectados: ninguno")
      Util.mostrar_mensaje("\n💡 Consejo: usa Taxi.NodeHelper.conectar_nodos() para conectar")
    else
      Util.mostrar_mensaje("Nodos conectados: #{inspect(nodos_conectados)}")
    end
  end

  @doc """
  Indica si existen nodos conectados actualmente.
  Devuelve true cuando hay al menos un nodo en `Node.list/0`.
  """
  def nodos_conectados? do
    not Enum.empty?(Node.list())
  end

  # === Funciones Privadas ===

  defp configurar_cookie do
    Node.set_cookie(@cookie)
  end

  defp conectar_automatico do
    # Nodos comunes a intentar conectar
    nodos_posibles = [:"cliente@localhost", :"conductor@localhost", :"servidor@localhost"]
    nodo_actual = node()

    # Filtrar el nodo actual
    nodos_a_intentar = Enum.reject(nodos_posibles, fn nodo -> nodo == nodo_actual end)

    "\n🔍 Buscando nodos disponibles..."
    |> Util.mostrar_mensaje()

    # Intentar conectar a cada nodo
    conectados = Enum.filter(nodos_a_intentar, fn nodo ->
      conectar_a_nodo(nodo)
    end)

    # Verificar si se conectó a alguno
    if Enum.empty?(conectados) do
      "\n⚠️  No se encontraron nodos disponibles"
      |> Util.mostrar_mensaje()

      "💡 Asegúrate de iniciar otro nodo primero"
      |> Util.mostrar_mensaje()

      :no_conectado
    else
      "\n✅ Conexión exitosa"
      |> Util.mostrar_mensaje()

      :ok
    end
  end

  defp conectar_a_nodo(nodo) do
    case Node.connect(nodo) do
      true ->
        "✅ Conectado a: #{nodo}"
        |> Util.mostrar_mensaje()
        true
      _ ->
        false
    end
  end

  defp conectar_especifico(nodo) do
    case Node.connect(nodo) do
      true ->
        "✅ Conectado a: #{nodo}"
        |> Util.mostrar_mensaje()
        :ok

      false ->
        "❌ No se pudo conectar a: #{nodo}"
        |> Util.mostrar_error()
        :error

      :ignored ->
        "ℹ️  Ya conectado a: #{nodo}"
        |> Util.mostrar_mensaje()
        :ok
    end
  end
end
