# rover-edu-code

## El Problema de Negocio
La enseñanza tradicional de la programación a menudo se enfrenta a un problema histórico: la abstracción excesiva. Los estudiantes de primeros años suelen abandonar la informática o sentirse frustrados debido a la monotonía de los tutoriales secos y las aulas convencionales, donde es difícil visualizar cómo funciona el código en el mundo real. Conceptos complejos como la Programación Orientada a Objetos (POO) resultan especialmente difíciles de asimilar sin ejemplos tangibles.

## Nuestra Solución: Edu_Code
Edu_Code resuelve esta barrera transformando la frustración en aprendizaje mediante la gamificación. Proporcionamos una plataforma interactiva donde los conceptos abstractos de la POO se reflejan de forma visual e inmediata sobre un modelo 3D (un Rover minero). Al exigir al jugador que escriba código real para automatizar procesos y sobrevivir, el sistema enseña a optimizar rutinas y comprender objetos, métodos y atributos de una manera inolvidable y altamente práctica.

---

# Arquitectura del Sistema
El proyecto "Edu_Code" está estructurado bajo una arquitectura modular dividida en cuatro pilares principales, garantizando un rendimiento fluido y una separación de responsabilidades clara:

Núcleo Lógico y Analizador Léxico (Parser): Es el cerebro del sistema. Se encarga de capturar el texto ingresado por el usuario, realizar el análisis léxico para validar la sintaxis de Programación Orientada a Objetos (exigiendo la notación de punto, por ejemplo: mi_rover.avanzar()) y traducir estas instrucciones en comandos procesables por el motor. Además, incorpora un sistema de seguridad algorítmica (timeout) para aislar la ejecución y evitar que bucles infinitos accidentales congelen la aplicación.

Motor Gráfico y Físicas 3D: Desarrollado nativamente en Godot Engine. Este módulo gestiona el entorno visual y las colisiones del juego. Utiliza un sistema basado en cuadrículas modulares (GridMap) para generar el terreno del asteroide y un controlador físico de cinemática (CharacterBody3D) para gestionar los desplazamientos y las interacciones del Rover minero en tiempo real.

Interfaz de Usuario (UI) y Gamificación: Actúa como el puente interactivo entre el jugador y la lógica subyacente. Incluye un Entorno de Desarrollo Integrado (IDE) in-game construido para procesar código y ofrecer resaltado de sintaxis, junto con paneles dinámicos de "Inspector POO" que reflejan visualmente el cambio de estado de los objetos. También gestiona la lógica de la tienda y el inventario del usuario.

Backend y Cloud Computing: Es la capa de infraestructura externa gestionada mediante Backend as a Service (Supabase/Firebase). Se encarga de la autenticación segura de los usuarios y utiliza bases de datos no relacionales para garantizar la persistencia asíncrona del progreso del jugador (guardando el inventario de minerales, los niveles superados y los fragmentos de código desbloqueados) sin interrumpir el flujo del juego.

---

# Tecnología Usada (Tech Stack)
Para garantizar que el proyecto mantenga un rendimiento óptimo tanto en el procesamiento lógico como en el renderizado gráfico, Edu_Code está construido utilizando herramientas especializadas y open-source:

Motor de Videojuegos: Godot Engine (v4.x - Estándar). Elegido por su arquitectura nativa orientada a objetos (nodos) y su ligereza.

Lenguaje de Scripting: GDScript. Utilizado para el desarrollo general del juego y para programar el analizador léxico (Parser) interno del jugador.

Nodos Clave: GridMap (para el entorno modular) y CharacterBody3D (para las físicas del Rover).

Interfaz y Entorno (IDE In-Game): Nodos TextEdit nativos de Godot, configurados con CodeHighlighter para ofrecer una experiencia real de resaltado de sintaxis, numeración de líneas y menús desplegables.

Backend y Persistencia (Nube): Supabase. Seleccionados como infraestructura Backend as a Service (BaaS).

Base de Datos: No relacional (estructuras JSON) para almacenar asíncronamente el progreso, inventario y sintaxis desbloqueada de los usuarios sin interrumpir el Gameplay Loop.


Control de Versiones y Despliegue: Git y GitHub para el repositorio del equipo , junto con GitHub Desktop para facilitar la integración continua. La Landing Page promocional será desplegada mediante hosting gratuito como  Vercel

---

# Mapa de Carpetas (Estructura del Proyecto)
## Para facilitar la lectura y escalabilidad del código bajo la metodología Scrum, el proyecto en Godot está estructurado de la siguiente manera:

```text
 Edu_Code/
├──  assets/            # Modelos 3D (.glb/.gltf), texturas, materiales y sonidos
├──  scenes/            # Nodos y escenas visuales de Godot
│   ├──  mundo.tscn     # Escena principal (GridMap, iluminación y cámara)
│   ├──  rover.tscn     # Escena del jugador (CharacterBody3D)
│   └──  main_menu.tscn # Interfaz de inicio (Jugar, Configuraciones, Salir)
├──  scripts/           # Lógica central en GDScript
│   ├──  parser.gd      # Analizador léxico y validación algorítmica de código
│   ├──  rover.gd       # Funciones de movimiento y POO del vehículo
│   └──  ui_manager.gd  # Control de menús e interacciones del jugador
├──  database/          # Archivos de conexión y lógica en la nube
│   └──  supabase.gd    # SDK y scripts de conexión con el Backend as a Service
├──  project.godot      # Archivo de configuración general del motor de juego
└──  README.md
```

---

# Metodología y Sprints de Desarrollo
El desarrollo de Edu_Code se gestiona bajo el marco de trabajo ágil Scrum. Para garantizar un avance fluido y evitar cuellos de botella técnicos, el proyecto se estructuró dividiendo la arquitectura en áreas aisladas, trabajando en Sprints de desarrollo.

La asignación de responsabilidades y la ejecución real de los primeros Sprints se han distribuido de la siguiente manera para levantar el Producto Mínimo Viable (MVP):

Sprint Lógico y Entorno 3D: Encargado de la inicialización del repositorio base. Comprende la creación del entorno isométrico (GridMap), el desarrollo físico del Rover y el hito crítico de conectar el analizador léxico (Parser) con el modelo 3D para que el vehículo responda a las instrucciones de código. (Fase completada)

Sprint de Interfaz (UI) y Navegación: Encargado de la capa visual del usuario fuera del gameplay. Comprende el desarrollo y diseño de la interfaz de menús principales, habilitando la navegación funcional entre las pantallas de "Jugar", "Configuraciones" y "Salir". (Fase completada)

Sprint de Cloud e Infraestructura: Encargado de la arquitectura de red. Comprende la configuración y conexión exitosa del proyecto en Godot con el entorno de Supabase, preparando el terreno para la autenticación y bases de datos. (Fase completada)

Próximos Sprints (Backlog actual): El equipo se enfocará en las mecánicas de gamificación (recolección de minerales), la validación de condiciones de victoria y la persistencia asíncrona de datos en la nube (guardado de progreso).

---
