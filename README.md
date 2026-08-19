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

