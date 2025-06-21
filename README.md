# MiMoApp

MiMoApp es un cliente iOS basado en SwiftUI que permite interactuar con un servidor de **LM Studio** para utilizar modelos de lenguaje locales. Incluye una interfaz de chat con soporte para imágenes (en modelos compatibles) y opciones para gestionar varias conversaciones.

## Características

- Gestión de conversaciones con pestañas dinámicas.
- Envío de mensajes de texto y, si el modelo lo permite, imágenes.
- Recuperación de la lista de modelos disponibles desde el servidor.
- Streaming de respuestas para una experiencia fluida.
- Configuración persistente de dirección, puerto y modelo seleccionado.
- Apartado para programar tareas automáticas mediante selección de fecha y hora. Las tareas se ejecutan automáticamente, se marcan con una palomita verde al completarse y guardan el registro de la respuesta obtenida. Si la tarea incluye imágenes sólo podrá ejecutarse con el modelo actual y éste no se podrá cambiar hasta que finalice.

## Requisitos

- macOS con Xcode 15 o superior.
- Un servidor de LM Studio en funcionamiento al que se pueda acceder mediante su API (por defecto en `http://IP:PUERTO`).

## Instalación

1. Clona este repositorio:
   ```bash
   git clone <este repositorio>
   ```
2. Abre `MiMoApp.xcodeproj` con Xcode.
3. Ejecuta el proyecto en un simulador o dispositivo físico.

## Uso

1. En la primera ejecución pulsa el botón de **configuración** para introducir la dirección y el puerto de tu instancia de LM Studio.
2. Pulsa **Recuperar modelos** para obtener la lista disponible y elige uno de ellos.
3. Vuelve a la pantalla principal y comienza a chatear. Si el modelo admite imágenes podrás seleccionarlas desde la cámara o la galería.
4. Puedes crear nuevas conversaciones, cambiar de modelo en cualquier momento o detener la respuesta en curso.
5. Accede al apartado de **tareas programadas** para añadir acciones automáticas eligiendo la fecha y hora de ejecución e incluso adjuntar imágenes si el modelo lo permite. Si alguna tarea incluye imágenes no podrás cambiar de modelo hasta que se complete. Las tareas finalizadas muestran una palomita verde y guardan el texto devuelto, el cual puedes seleccionar o copiar desde su menú contextual.

## Pruebas

Este proyecto incluye proyectos de prueba unitarios y de interfaz (en `MiMoAppTests` y `MiMoAppUITests`). Para ejecutarlos desde Xcode selecciona el esquema de pruebas y pulsa **Cmd+U**.

---

Licencia MIT.
