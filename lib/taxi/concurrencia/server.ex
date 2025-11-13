defmodule Taxi.Server do
  @moduledoc """
  Servidor principal que coordina las operaciones del sistema de viajes.
  Funciones clave:
  - Crear viajes y asignar identificadores incrementales.
  - Listar viajes disponibles localmente y en otros nodos conectados.
  - Aceptar viajes (local o remotamente) aplicando búsqueda distribuida.
  - Limpiar viajes finalizados o expirados.

  Representa el punto central de comunicación.
  Usa GenServer para mantener estado consistente de viajes activos.
  """

  use GenServer
  alias Taxi.{Supervisor, TripServer, Trip}

  @nombre_servicio :taxi_server

  # === API Pública ===

  @doc """
  Inicia el servidor principal y registra el proceso bajo un nombre global.
  Su estado inicial contiene el contador de IDs y el mapa de viajes activos.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @nombre_servicio)
  end

  @doc """
  Solicita la creación de un nuevo viaje para un cliente.
  Recibe cliente, origen y destino.
  Devuelve {:ok, trip} o {:error, mensaje}.
  """
  def solicitar_viaje(cliente, origen, destino) do
    GenServer.call(@nombre_servicio, {:solicitar_viaje, cliente, origen, destino})
  end

  @doc """
  Lista viajes pendientes disponibles.
  Incluye viajes locales y también viajes en nodos remotos conectados (Node.list/0).
  Devuelve una lista de structs Trip.
  """
  def listar_viajes_disponibles do
    viajes_locales = GenServer.call(@nombre_servicio, :listar_viajes)
    viajes_remotos = buscar_viajes_en_otros_nodos()
    viajes_locales ++ viajes_remotos
  end

  @doc """
  Intenta aceptar un viaje por ID para un conductor.
  Primero busca localmente y si no lo encuentra, intenta en nodos remotos.
  Devuelve {:ok, trip} o {:error, mensaje}.
  """
  def aceptar_viaje(trip_id, conductor) do
    case GenServer.call(@nombre_servicio, {:aceptar_viaje, trip_id, conductor}) do
      {:ok, viaje} -> {:ok, viaje}
      {:error, "Viaje no encontrado"} ->
        aceptar_viaje_remoto(trip_id, conductor)
      error -> error
    end
  end

  # === Callbacks GenServer ===

  @doc """
  Inicializa el estado interno del servidor.
  Prepara el mapa de viajes y el contador de IDs.
  """
  def init(_) do
    Util.mostrar_mensaje("🚀 Servidor de viajes iniciado")
    estado = %{
      viajes: %{},
      next_id: 1
    }
    {:ok, estado}
  end

  @doc """
  Maneja la creación de un viaje nuevo.
  Genera un ID, inicia el proceso supervisado y registra su PID.
  """
  def handle_call({:solicitar_viaje, cliente, origen, destino}, _from, estado) do
    trip_id = estado.next_id

    datos_viaje = %{
      id: trip_id,
      cliente: cliente,
      origen: origen,
      destino: destino
    }

    case Supervisor.iniciar_viaje(datos_viaje) do
      {:ok, pid} ->
        nuevos_viajes = Map.put(estado.viajes, trip_id, pid)
        nuevo_estado = %{estado | viajes: nuevos_viajes, next_id: trip_id + 1}
        viaje = TripServer.obtener_estado(pid)
        {:reply, {:ok, viaje}, nuevo_estado}

      _error ->
        {:reply, {:error, "No se pudo crear el viaje"}, estado}
    end
  end

  @doc """
  Maneja la solicitud de listar viajes pendientes locales.
  Filtra procesos vivos y devuelve solo los viajes en estado :pendiente.
  """
  def handle_call(:listar_viajes, _from, estado) do
    viajes = estado.viajes
    |> Map.values()
    |> Enum.map(fn pid ->
      if Process.alive?(pid) do
        TripServer.obtener_estado(pid)
      else
        nil
      end
    end)
    |> Enum.filter(fn viaje ->
      viaje != nil && viaje.estado == :pendiente
    end)

    {:reply, viajes, estado}
  end

  @doc """
  Maneja la aceptación local de un viaje.
  Verifica existencia y estado del proceso antes de delegar al TripServer.
  """
  def handle_call({:aceptar_viaje, trip_id, conductor}, _from, estado) do
    pid = Map.get(estado.viajes, trip_id)

    if pid != nil && Process.alive?(pid) do
      case TripServer.aceptar(pid, conductor) do
        {:ok, viaje} -> {:reply, {:ok, viaje}, estado}
        error -> {:reply, error, estado}
      end
    else
      {:reply, {:error, "Viaje no encontrado"}, estado}
    end
  end

  @doc """
  Limpia un viaje del registro interno.
  Se usa cuando el proceso terminó (expirado o completado).
  """
  def handle_cast({:limpiar_viaje, trip_id}, estado) do
    nuevos_viajes = Map.delete(estado.viajes, trip_id)
    {:noreply, %{estado | viajes: nuevos_viajes}}
  end

  # === Funciones Privadas para Comunicación entre Nodos ===

  @doc """
  Busca viajes pendientes en otros nodos conectados.
  Ignora nodos que no respondan en el tiempo límite.
  Uso interno para extender disponibilidad del sistema.
  """
  defp buscar_viajes_en_otros_nodos do
    Node.list()
    |> Enum.flat_map(fn nodo ->
      try do
        GenServer.call({@nombre_servicio, nodo}, :listar_viajes, 5_000)
      catch
        :exit, _ -> []
      end
    end)
  end

  @doc """
  Intenta aceptar un viaje remoto recorriendo nodos conectados.
  Se detiene al encontrar el primero disponible.
  Retorna {:ok, trip} o {:error, "Viaje no encontrado"}.
  """
  defp aceptar_viaje_remoto(trip_id, conductor) do
    Node.list()
    |> Enum.reduce_while({:error, "Viaje no encontrado"}, fn nodo, _acc ->
      try do
        case GenServer.call({@nombre_servicio, nodo}, {:aceptar_viaje, trip_id, conductor}, 5_000) do
          {:ok, viaje} -> {:halt, {:ok, viaje}}
          _ -> {:cont, {:error, "Viaje no encontrado"}}
        end
      catch
        :exit, _ -> {:cont, {:error, "Viaje no encontrado"}}
      end
    end)
  end
end
