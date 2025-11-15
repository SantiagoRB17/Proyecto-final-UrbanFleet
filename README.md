# 🚕 UrbanFleet - Sistema Distribuido de Taxis

**Proyecto Final - Programación 3**  
*Sistema de gestión de viajes distribuido construido con Elixir/OTP*

---

## 👥 Autores

**Santiago Ramirez Bernal**  
**Laura Sofia Osoario**  
**Maria Camila Melo Marin**  

Universidad del Quindio

---

## 📖 Descripción

**UrbanFleet** es un sistema distribuido de gestión de viajes tipo taxi que permite a clientes solicitar viajes y a conductores aceptarlos en tiempo real. El sistema está diseñado para ejecutarse en múltiples nodos conectados en red, demostrando conceptos avanzados de programación concurrente y distribuida usando Elixir.

### Funcionalidades Principales

- 🔐 **Autenticación de usuarios** con roles diferenciados (cliente/conductor)
- 🚗 **Solicitud de viajes** por parte de clientes
- 🚕 **Aceptación de viajes** por parte de conductores
- 🌐 **Sistema distribuido** con múltiples nodos comunicándose
- 📊 **Sistema de ranking y puntajes** para usuarios
- ⏱️ **Gestión automática** de viajes (expiración y completado)
- 💾 **Persistencia de datos** en formato JSON

---

## ✨ Características

### Para Clientes
- ✅ Registro e inicio de sesión
- ✅ Solicitar viajes especificando origen y destino
- ✅ Consultar puntaje personal
- ✅ Ver rankings del sistema

### Para Conductores
- ✅ Registro e inicio de sesión
- ✅ Listar viajes disponibles (locales y remotos)
- ✅ Aceptar viajes de clientes
- ✅ Consultar puntaje personal
- ✅ Ver rankings del sistema

### Características Técnicas
- 🔄 **Concurrencia**: procesos supervisados para cada viaje
- 🌐 **Distribución**: comunicación entre nodos Erlang
- 💪 **Tolerancia a fallos**: supervisores con estrategia `one_for_one`
- 📦 **Persistencia**: almacenamiento en JSON
- 🧪 **Testing**: pruebas de integración y unitarias

---

## 🏗️ Arquitectura

### Capas del Sistema

1. **Presentación** (`lib/taxi/Presentacion/`)
   - `CLI.ex`: Interfaz de línea de comandos
   - `Util.ex`: Utilidades de entrada/salida

2. **Servicios** (`lib/taxi/Servicios/`)
   - `AuthManager.ex`: Gestión de autenticación
   - `UserManager.ex`: Operaciones de usuarios
   - `LocationManager.ex`: Gestión de ubicaciones
   - `RankingManager.ex`: Sistema de puntajes
   - `NodeHelper.ex`: Comunicación entre nodos

3. **Concurrencia** (`lib/taxi/Concurrencia/`)
   - `Application.ex`: Punto de entrada OTP
   - `Server.ex`: Servidor principal de viajes
   - `Supervisor.ex`: Supervisor dinámico de viajes
   - `TripServer.ex`: Proceso individual por viaje

4. **Dominio** (`lib/taxi/Dominio/`)
   - `User.ex`: Estructura de usuario
   - `Trip.ex`: Estructura de viaje
   - `Location.ex`: Estructura de ubicación
   - `Session.ex`: Estructura de sesión

5. **Persistencia** (`lib/taxi/Persistencia/`)
   - `Persistencia.ex`: Módulo base
   - `UserPersistence.ex`: Persistencia de usuarios
   - `TripPersistence.ex`: Persistencia de viajes
   - `LocationPersistence.ex`: Persistencia de ubicaciones

---

## 🔧 Requisitos

- **Elixir**: >= 1.18
- **Erlang/OTP**: >= 27
- **Sistema Operativo**: Windows, macOS, Linux
- **Dependencias**:
  - `jason ~> 1.4` (codificación/decodificación JSON)

---

## 📦 Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/SantiagoRB17/Proyecto-final-UrbanFleet.git
cd proyecto_final
```

### 2. Instalar dependencias

```bash
mix deps.get
```

### 3. Compilar el proyecto

```bash
mix compile
```

---

## 🚀 Uso

### Modo Simple (Un solo nodo)

```bash
iex -S mix
```

En la consola de IEx:

```elixir
iex> Taxi.CLI.iniciar()
```

### Modo Distribuido (Múltiples nodos)

#### Terminal 1 - Nodo Principal
```bash
iex --sname nodo1 --cookie secreto -S mix
```

#### Terminal 2 - Nodo Secundario
```bash
iex --sname nodo2 --cookie secreto -S mix
```

#### Terminal 3 - Nodo Terciario
```bash
iex --sname nodo3 --cookie secreto -S mix
```

En cualquier terminal:
```elixir
iex> Taxi.CLI.iniciar()
```

### Flujo de Uso Típico

#### Como Cliente:

1. Ejecutar `Taxi.CLI.iniciar()`
2. Seleccionar `conectar`
3. Ingresar credenciales y seleccionar rol "Cliente"
4. Usar comando `solicitar` para pedir un viaje
5. Ingresar origen y destino
6. Esperar a que un conductor acepte el viaje

#### Como Conductor:

1. Ejecutar `Taxi.CLI.iniciar()`
2. Seleccionar `conectar`
3. Ingresar credenciales y seleccionar rol "Conductor"
4. Usar comando `listar` para ver viajes disponibles
5. Usar comando `aceptar` e ingresar el ID del viaje
6. El viaje se completa automáticamente

### Comandos Disponibles

#### Comandos Generales:
- `conectar` - Iniciar sesión
- `desconectar` - Cerrar sesión
- `nodos` - Ver nodos conectados
- `red` - Diagnóstico de red
- `ranking` - Ver rankings del sistema
- `ayuda` - Mostrar ayuda
- `salir` - Salir del programa

#### Comandos de Cliente:
- `solicitar` - Solicitar un nuevo viaje
- `puntaje` - Ver puntaje personal

#### Comandos de Conductor:
- `listar` - Ver viajes disponibles
- `aceptar` - Aceptar un viaje
- `puntaje` - Ver puntaje personal

---

## 🎓 Conceptos de Programación 3

Este proyecto demuestra los siguientes conceptos de la materia:

### 1. **Procesos y Concurrencia**
- Cada viaje se ejecuta en su propio proceso (`TripServer`)
- Comunicación entre procesos usando mensajes
- Uso de `GenServer` para mantener estado

```elixir
# Ejemplo en TripServer.ex
use GenServer

def handle_call({:aceptar, conductor}, _from, viaje) do
  # Lógica concurrente...
end
```

### 2. **Supervisión (OTP)**
- Árbol de supervisión con `Application`
- `DynamicSupervisor` para procesos temporales (viajes)
- Estrategia `one_for_one` para reinicio individual

```elixir
# Ejemplo en Supervisor.ex
def init(_init_arg) do
  DynamicSupervisor.init(strategy: :one_for_one)
end
```

### 3. **Programación Distribuida**
- Comunicación entre nodos Erlang (`Node.list()`, `Node.connect()`)
- Llamadas remotas a GenServers
- Búsqueda distribuida de viajes

```elixir
# Ejemplo en Server.ex
defp buscar_viajes_en_otros_nodos do
  Node.list()
  |> Enum.flat_map(fn nodo ->
    GenServer.call({@nombre_servicio, nodo}, :listar_viajes)
  end)
end
```

### 4. **Persistencia de Datos**
- Serialización con Jason (JSON)
- Lectura/escritura de archivos
- Gestión de datos estructurados

```elixir
# Ejemplo en Persistencia.ex
def guardar_datos(datos, archivo) do
  json = Jason.encode!(datos, pretty: true)
  File.write!(archivo, json)
end
```

### 5. **Estructuras de Datos Inmutables**
- Uso de `structs` para modelar dominio
- Pattern matching
- Transformaciones funcionales

```elixir
# Ejemplo en Trip.ex
defstruct [:id, :cliente, :conductor, :origen, :destino, :estado]
```

### 6. **Manejo de Estado**
- Estado inmutable en GenServers
- Actualización funcional del estado
- Estado compartido controlado

### 7. **Timeouts y Temporizadores**
- Expiración automática de viajes (40 segundos)
- Completado automático de viajes (5 segundos)
- Uso de `Process.send_after/3`

---

## 📁 Estructura del Proyecto

```
proyecto_final/
├── lib/
│   └── taxi/
│       ├── Concurrencia/
│       │   ├── Application.ex      # Supervisor principal OTP
│       │   ├── Server.ex            # Servidor de viajes
│       │   ├── Supervisor.ex        # Supervisor dinámico
│       │   └── TripServer.ex        # Proceso por viaje
│       ├── Dominio/
│       │   ├── Location.ex          # Estructura de ubicación
│       │   ├── Session.ex           # Estructura de sesión
│       │   ├── Trip.ex              # Estructura de viaje
│       │   └── User.ex              # Estructura de usuario
│       ├── Persistencia/
│       │   ├── LocationPersistence.ex
│       │   ├── Persistencia.ex      # Módulo base
│       │   ├── TripPersistence.ex
│       │   └── UserPersistence.ex
│       ├── Presentacion/
│       │   ├── CLI.ex               # Interfaz de usuario
│       │   └── Util.ex              # Utilidades I/O
│       └── Servicios/
│           ├── AuthManager.ex       # Autenticación
│           ├── LocationManager.ex   # Gestión ubicaciones
│           ├── NodeHelper.ex        # Comunicación nodos
│           ├── RankingManager.ex    # Sistema de puntajes
│           └── UserManager.ex       # Gestión usuarios
├── test/
│   ├── integration_test.exs         # Pruebas de integración
│   ├── location_manager_test.exs    # Pruebas de ubicaciones
│   ├── persistencia_test.exs        # Pruebas de persistencia
│   └── test_helper.exs
├── data/
│   ├── locations.json               # Ubicaciones precargadas
│   └── users.json                   # Usuarios registrados
├── mix.exs                          # Configuración del proyecto
└── README.md
```

---

## 🔍 Características Avanzadas

### Sistema Distribuido

- **Descubrimiento automático**: Los nodos buscan otros nodos al iniciar
- **Tolerancia a fallos**: Si un nodo falla, otros continúan operando
- **Búsqueda distribuida**: Los viajes se buscan en todos los nodos conectados
- **Diagnóstico de red**: Herramientas para monitorear y gestionar la red

### Gestión de Viajes

- **Expiración automática**: Viajes no aceptados expiran en 40 segundos
- **Completado automático**: Viajes aceptados se completan automaticamente
- **Estados de viaje**: `:pendiente`, `:en_progreso`, `:completado`, `:expirado`
- **Limpieza automática**: Procesos finalizados se remueven del supervisor

### Sistema de Ranking

- **Ranking global**: Todos los usuarios ordenados por puntaje
- **Top conductores**: Los 10 mejores conductores
- **Top clientes**: Los 10 mejores clientes
- **Actualización en tiempo real**: Los puntajes se actualizan tras cada viaje

---

## 🧪 Pruebas

### Ejecutar todas las pruebas

```bash
mix test
```



