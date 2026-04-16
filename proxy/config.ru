#!/usr/bin/env ruby
# Archivo de entrada Rack para la app proxy.
# Carga la implementación del proxy y la ejecuta con `rackup`.
require_relative "app"

# Ejecuta la clase Sinatra `AvatarProxy` cuando se inicia Rack.
run AvatarProxy