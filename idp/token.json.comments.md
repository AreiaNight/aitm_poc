token.json — explicación de campos

- `secret`: clave usada para firmar cookies de sesión del IdP (HMAC). Se usa
  en el `use Rack::Session::Cookie` de `idp/app.rb`.
- `jwt_secret`: clave secreta usada para firmar/verificar tokens JWT (alg: HS256).

Nota: no es recomendable guardar secretos en archivos JSON en producción; usar
variables de entorno o un gestor de secretos.
