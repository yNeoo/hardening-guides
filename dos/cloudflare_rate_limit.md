# Cloudflare — rate limiting (producción, si el sitio está tras Cloudflare)

Si tu dominio real va por Cloudflare, usa su capa de protección en lugar de (o además de) nginx:

## Configuración recomendada (dashboard)

1. **Rate Limiting Rules** (Security → WAF → Rate limiting rules):
   - Regla: `(http.request.uri.path eq "/" or starts_with "/api/")`
   - Acción: **Block** (o Challenge) · límite: `20 requests/10 seconds`
   - Duración del bloqueo: `60 seconds`
2. **Security Level**: setéalo en *High* (las visitas sospechosas pasan challenge).
3. **Under Attack Mode**: actívalo temporalmente si hay un flood real (interactivo para robots, sigue dejando entrar a humanos).
4. **Bot Fight Mode / Bot Management** activado.

## Por qué

- Cloudflare absorbe el volumen antes de llegar a tu VPS (OVH `158.69.x.x`).
- Un DDoS volumétrico (millones de pps) se mitiga en el **edge**, no en tu nginx.
- Lo que Cloudflare no te puede proteger: **slowloris contra el origin** y el **application-layer** → por eso nginx `limit_req`/`limit_conn` + fail2ban del template `nginx_limits.conf` son complementos obligatorios.

## Verificación

```bash
# comprueba que el tráfico pasa por Cloudflare
curl -sI https://tusitio.com | grep -i server      # → cloudflare
# y que el origin solo acepta IPs de Cloudflare (lista oficial):
#   https://www.cloudflare.com/ips/   → crea regla de origen "allow only Cloudflare"
```