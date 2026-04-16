# Gemfile

# Fuente de gems: donde Bundler descargará las dependencias.
# Usamos RubyGems público para este PoC.
source "http://rubygems.org"

# Especifica la versión de Ruby esperada para ejecutar este proyecto.
ruby "3.3.0"

# Sinatra: micro-framework web usado para todas las apps (IdP, proxy, atacante).
gem "sinatra"

# Extensiones útiles para Sinatra (helpers, JSON responses, etc.).
gem "sinatra-contrib"

# Puma: servidor HTTP/Concurrent para ejecutar las aplicaciones Rack/Sinatra.
gem "puma"

# SQLite3 + Sequel: base de datos ligera y ORM usado para almacenar tokens/credenciales.
gem "sqlite3"
gem "sequel"

# JWT: librería para generar y verificar JSON Web Tokens (firmas HMAC).
gem "jwt"

# Rack session y rackup se usan para la gestión de sesiones y ejecución de Rack.
gem "rack-session"
gem "rackup"

# Cliente HTTP opcional (comentado): podría usarse en lugar de Net::HTTP.
# gem "faraday"

# Dotenv: carga variables de entorno desde .env durante desarrollo y tests.
gem 'dotenv', groups: [:development, :test]


