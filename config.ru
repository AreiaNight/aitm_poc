# config.ru
# Archivo de entrada Rack para ejecutar la app IdP desde `rackup`.
# `require_relative` carga la clase `AvatarIdP` definida en `idp/app.rb`.
require_relative "idp/app"

require 'rack'

# Exponer la carpeta `public` (CSS, imágenes) como recursos estáticos en `/css`.
use Rack::Static, urls: ["/css"], root: "public"

# Ejecuta la aplicación Sinatra principal definida como `AvatarIdP`.
run AvatarIdP