defmodule Taxi.AuthManager do
  @moduledoc """
  Gestor de autenticación y sesiones de usuarios.
  """

  use GenServer
  alias Taxi.{Session, UserPersistence, UserManager}

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def conectar(username, password, rol) do
    GenServer.call(__MODULE__, {:conectar, username, password, rol})
  end

  def desconectar(username) do
    GenServer.call(__MODULE__, {:desconectar, username})
  end

  def esta_conectado?(username) do
    GenServer.call(__MODULE__, {:esta_conectado, username})
  end

  def obtener_sesion(username) do
    GenServer.call(__MODULE__, {:obtener_sesion, username})
  end

  def contar_usuarios_conectados do
    GenServer.call(__MODULE__, :contar_usuarios)
  end

  # === Callbacks ===

  def init(_state) do
    Util.mostrar_mensaje("🔐 AuthManager iniciado")
    {:ok, %{}}
  end

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

  def handle_call({:desconectar, username}, _from, sesiones) do
    if Map.has_key?(sesiones, username) do
      Util.mostrar_mensaje("👋 Usuario desconectado: #{username}")
      nuevas_sesiones = Map.delete(sesiones, username)
      {:reply, {:ok, "Desconexión exitosa"}, nuevas_sesiones}
    else
      {:reply, {:error, "Usuario no está conectado"}, sesiones}
    end
  end

  def handle_call({:esta_conectado, username}, _from, sesiones) do
    conectado = Map.has_key?(sesiones, username)
    {:reply, conectado, sesiones}
  end

  def handle_call({:obtener_sesion, username}, _from, sesiones) do
    sesion = Map.get(sesiones, username)
    {:reply, sesion, sesiones}
  end

  def handle_call(:contar_usuarios, _from, sesiones) do
    conteo = map_size(sesiones)
    {:reply, conteo, sesiones}
  end
end
