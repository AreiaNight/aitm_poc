#!/bin/bash

# Script de arranque rápido (PoC). Comentarios explican cada paso.
# NOTA: este script asume que las dependencias ya están instaladas.

# Arranca el IdP en el puerto 4444 usando `rackup`.
bundle exec rackup -p 4444 &&

# Cambia al directorio del atacante y arranca su dashboard en 4445.
# (la ruta original tenía 'attack' — ajustar si la carpeta se llama `attacker`).
cd attacker && bundle exec rackup -p 4445 &&

# Volvemos al proyecto y arrancamos el proxy en 4446.
cd ..
cd proxy && bundle exec rackup -p 4446 &&