# Compra de tres casillas

Después de Ruta de calibración comienza la misión `comprar_casillas`.
El botón **+3 CASILLAS** de Mejoras cuesta 10 minerales almacenados en la nave.
Agrega una columna al este del corredor: el terreno pasa de 1×3 a 2×3.
La compra es única, completa la misión y muestra una confirmación de A.D.A.
No se permite comprar mientras se ejecuta un programa.

El mapa ampliado mantiene dos depósitos en casillas aleatorias distintas.
Cada mineral extraído se repone; los tutoriales anteriores conservan su
depósito fijo. La casilla inicial continúa siendo el punto de transferencia.

La compra solicita el guardado mediante ProgressService. `map_tier = 2`
representa ahora el sector 2×3. El antiguo sector 3×3 queda reservado en
`map_tier = 3`, sin compra habilitada. Si se habían creado manualmente partidas
con tier 2 para probar el antiguo 3×3, ahora restaurarán seis casillas.
No hay nuevos campos de base de datos.
