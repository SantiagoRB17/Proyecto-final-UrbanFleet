defmodule Taxi.Server do
  @moduledoc """
  Servidor principal que coordina las operaciones del sistema.
  Inspirado en el Problema 19 - IPC Remoto
  """
  
  use GenServer
  alias Taxi.{Supervisor, TripServer, Trip}
  
  # Nombre del servicio registrado globalmente (como en Problema 19)
  @nombre_servicio :taxi_server
  
  # === API Pública ===
  
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: @nombre_servicio)
  end
  
  @doc """
  Solicita un viaje. Similar a enviar mensaje en Problema 19.
  """
  def solicitar_viaje(cliente, origen, destino) do
    GenServer.call(@nombre_servicio, {:solicitar_viaje, cliente, origen, destino})
  end
  
  @doc """
  Lista viajes disponibles. Busca en nodo local Y nodos remotos.
  """
  def listar_viajes_disponibles do
    # Obtener viajes locales
    viajes_locales = GenServer.call(@nombre_servicio, :listar_viajes)
    
    # Buscar en nodos remotos (como en Problema 19)
    viajes_remotos = buscar_viajes_en_otros_nodos()
    
    viajes_locales ++ viajes_remotos
  end
  
  @doc """
  Acepta un viaje. Busca primero local, luego en nodos remotos.
  """
  def aceptar_viaje(trip_id, conductor) do
    # Intentar local primero
    case GenServer.call(@nombre_servicio, {:aceptar_viaje, trip_id, conductor}) do
      {:ok, viaje} -> {:ok, viaje}
      {:error, "Viaje no encontrado"} -> 
        # Buscar en otros nodos (patrón Problema 19)
        aceptar_viaje_remoto(trip_id, conductor)
      error -> error
    end
  end
  
  # === Callbacks GenServer ===
  
  def init(_) do
    Util.mostrar_mensaje("🚀 Servidor de viajes iniciado")
    estado = %{
      viajes: %{},  # Map de trip_id => pid
      next_id: 1
    }
    {:ok, estado}
  end
  
  def handle_call({:solicitar_viaje, cliente, origen, destino}, _from, estado) do
    trip_id = estado.next_id
    
    datos_viaje = %{
      id: trip_id,
      cliente: cliente,
      origen: origen,
      destino: destino
    }
    
    # Crear proceso supervisado para el viaje
    case Supervisor.iniciar_viaje(datos_viaje) do
      {:ok, pid} ->
        nuevos_viajes = Map.put(estado.viajes, trip_id, pid)
        nuevo_estado = %{estado | viajes: nuevos_viajes, next_id: trip_id + 1}
        
        # Obtener el viaje creado
        viaje = TripServer.obtener_estado(pid)
        {:reply, {:ok, viaje}, nuevo_estado}
      
      error ->
        {:reply, {:error, "No se pudo crear el viaje"}, estado}
    end
  end
  
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
  
  # Limpiar viajes completados o expirados
  def handle_cast({:limpiar_viaje, trip_id}, estado) do
    nuevos_viajes = Map.delete(estado.viajes, trip_id)
    {:noreply, %{estado | viajes: nuevos_viajes}}
  end
  
  # === Funciones Privadas para Comunicación entre Nodos ===
  
  defp buscar_viajes_en_otros_nodos do
    Node.list()
    |> Enum.flat_map(fn nodo ->
      try do
        # Llamada remota al servidor en otro nodo
        GenServer.call({@nombre_servicio, nodo}, :listar_viajes, 5_000)
      catch
        :exit, _ -> []
      end
    end)
  end
  
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
