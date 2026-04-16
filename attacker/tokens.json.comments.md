tokens.json — explicación de campos

- `secret`: clave usada por la app del atacante para firmar/leer cookies de sesión del proxy.
- `jwt_secret`: secreto usado para intentar decodificar/verificar JWT capturados.

Este archivo solo sirve en el PoC para permitir al dashboard del atacante validar tokens.
En entornos reales, los secretos no deberían almacenarse en ficheros dentro del repo.
