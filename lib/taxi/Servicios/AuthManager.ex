defmodule Taxi.AuthManager do
  @moduledoc """
  Gestor de autenticación y sesiones de usuarios.
  """

  use GenServer
  alias Taxi.{Session, UserPersistence, UserManager}

  @doc """
  Inicia el proceso del gestor de autenticación y lo registra por nombre de módulo.
  Retorna {:ok, pid} o {:error, razon}.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Conecta un usuario con `username`, `password` y `rol`.
  - Si el usuario no existe, se registra y se crea su sesión.
  - Si existe, se valida la contraseña y se crea la sesión.
  Retorna {:ok, mensaje} o {:error, mensaje}.
  """
  def conectar(username, password, rol) do
    GenServer.call(__MODULE__, {:conectar, username, password, rol})
  end

  @doc """
  Desconecta un usuario activo, eliminando su sesión.
  Retorna {:ok, mensaje} si existía o {:error, "Usuario no está conectado"} si no.
  """
  def desconectar(username) do
    GenServer.call(__MODULE__, {:desconectar, username})
  end

  @doc """
  Indica si un usuario se encuentra conectado en este nodo.
  Devuelve true o false.
  """
  def esta_conectado?(username) do
    GenServer.call(__MODULE__, {:esta_conectado, username})
  end

  @doc """
  Obtiene la sesión asociada a un `username` si está conectada.
  Devuelve `%Session{}` o `nil`.
  """
  def obtener_sesion(username) do
    GenServer.call(__MODULE__, {:obtener_sesion, username})
  end

  @doc """
  Devuelve la cantidad de usuarios actualmente conectados en este nodo.
  """
  def contar_usuarios_conectados do
    GenServer.call(__MODULE__, :contar_usuarios)
  end

  # === Callbacks ===

  @doc """
  Inicializa el estado interno del GenServer como un mapa vacío de sesiones.
  Emite un mensaje informativo al iniciar.
  """
  def init(_state) do
    Util.mostrar_mensaje("🔐 AuthManager iniciado")
    {:ok, %{}}
  end

  @doc """
  Maneja la conexión de un usuario. Si ya está conectado, rechaza la acción.
  Si no existe en persistencia, lo registra y crea su sesión. Si existe, valida la contraseña.
  """
  def handle_call({:conectar, username, password, rol}, _from, sesiones) do
    if Map.has_key?(sesiones, username) do
      {:reply, {:error, "Usuario ya conectado"}, sesiones}
    else
      usuario = UserPersistence.find_by_name(username)

      if usuario == nil do
        # Registrar nuevo usuario
        Util.mostrar_mensaje("📝 Registrando usuario: #{username}")
        nuevo_usuario = UserManager.crear(username, password, rol)
        UserPersistence.save(nuevo_usuario)

        # Crear sesión
        sesion = Session.crear(username, rol)
        nuevas_sesiones = Map.put(sesiones, username, sesion)

        {:reply, {:ok, "Usuario registrado y conectado"}, nuevas_sesiones}
      else
        # Verificar contraseña
        if usuario.password == password do
          Util.mostrar_mensaje("✅ Usuario conectado: #{username}")
          sesion = Session.crear(username, usuario.rol)
          nuevas_sesiones = Map.put(sesiones, username, sesion)

          {:reply, {:ok, "Conexión exitosa"}, nuevas_sesiones}
        else
          {:reply, {:error, "Contraseña incorrecta"}, sesiones}
        end
      end
    end
  end

  @doc """
  Maneja la desconexión de un usuario activo, removiendo su sesión del estado.
  Si el usuario no está conectado, informa el error.
  """
  def handle_call({:desconectar, username}, _from, sesiones) do
    if Map.has_key?(sesiones, username) do
      Util.mostrar_mensaje("👋 Usuario desconectado: #{username}")
      nuevas_sesiones = Map.delete(sesiones, username)
      {:reply, {:ok, "Desconexión exitosa"}, nuevas_sesiones}
    else
      {:reply, {:error, "Usuario no está conectado"}, sesiones}
    end
  end

  @doc """
  Responde si un `username` existe en el mapa de sesiones activas.
  Devuelve un booleano.
  """
  def handle_call({:esta_conectado, username}, _from, sesiones) do
    conectado = Map.has_key?(sesiones, username)
    {:reply, conectado, sesiones}
  end

  @doc """
  Devuelve la sesión asociada a un `username` (o nil si no está conectado).
  """
  def handle_call({:obtener_sesion, username}, _from, sesiones) do
    sesion = Map.get(sesiones, username)
    {:reply, sesion, sesiones}
  end

  @doc """
  Calcula y retorna el número de entradas en el mapa de sesiones activas.
  """
  def handle_call(:contar_usuarios, _from, sesiones) do
    conteo = map_size(sesiones)
    {:reply, conteo, sesiones}
  end
end
