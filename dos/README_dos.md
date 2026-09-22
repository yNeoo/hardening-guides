# Prueba de resistencia (DoS/Load) en local — y cómo blindar producción

> **Regla de oro:** todo esto se lanza contra **tu staging local** (`localhost`). Jamás contra la web en producción. La web en producción se **confirma** con métricas reales ligeras, no se "prueba hasta que ceda".

## 1. Herramientas instaladas (Windows, sin WSL)

| Herramienta | Qué es | Dónde |
|---|---|---|
| **k6** | Load testing profesional (Grafana): RPS, latencias, vus | `scoop`: `k6` |
| **vegeta** | Attack tool HTTP en Go, ideal para picos | `scoop`: `vegeta` |
| **slowloris** | DoS de baja tasa (mantiene sockets abiertos) | `pip install slowloris` |
| **ab / hping3 / siege / wrk** | Los clásicos Linux | Requieren **WSL** (ver §5) |

## 2. Objetivo local: staging en Docker

```powershell
cd C:\Users\zorro\Downloads\staging
docker compose up -d
curl http://localhost:8080/          # → 200 "Staging BoyzGang - OK"
```

## 3. Lanzar los ataques → localhost:8080

### k6 (escalonado — busca el punto de rotura)

Crea `script.js`:

```javascript
import http from "k6/http";
import { check } from "k6";

export const options = {
  stages: [                     // sube de a poco
    { duration: "20s", target: 100 },   // vus
    { duration: "20s", target: 500 },
    { duration: "30s", target: 2000 },
    { duration: "20s", target: 0 },
  ],
};

export default function () {
  const r = http.get("http://localhost:8080/");
  check(r, { "200": (res) => res.status === 200 });
}
```

```powershell
k6 run script.js
# Mira: http_req_duration (p95/p99), http_req_failed, throughput
# "http_req_failed" sube o p95 explota → encontraste el techo.
```

### vegeta (pico fijo)

```powershell
echo "GET http://localhost:8080/" | vegeta attack -duration=60s -rate=500 -workers=50 | vegeta report
```

### slowloris (misma IP, sockets lentos — nginx local)

```powershell
python -m slowloris 127.0.0.1 -p 8080 -s 200
# La web "cuelga" con conexiones abiertas: revisa con docker stats cuánto aguanta (poco)
```

### Abrir el balde todo junto

```powershell
# terminal 1 — slowloris
python -m slowloris 127.0.0.1 -p 8080 -s 300
# terminal 2 — vegeta
echo "GET http://localhost:8080/" | vegeta attack -duration=60s -rate=max -workers=100 | vegeta report
# (cuando termines: docker compose down)
```

## 4. Cómo leer el colapso

| Señal | Significa |
|---|---|
| `http_req_failed` sube | Peticiones perdiéndose: saturación |
| `p95/p99` de 50 ms → 2-5 s | Cola: workers de PHP agotados |
| `502/503` de nginx | `pm.max_children` alcanzado — techo real de PHP-FPM |
| RPS "estancado" muy por debajo del pedido | El servidor cedió (déficit de throughput) |

## 5. Herramientas Linux (hping3, siege, wrk, ab) — opcional con WSL

Si las quieres, instala WSL (admin + reinicio):

```powershell
wsl --install -d Ubuntu
wsl
# dentro de WSL:
sudo apt update && sudo apt install -y hping3 siege apache2-utils wrk
# luego contra el staging (local):
siege -c 200 -t 60s http://localhost:8080/
ab -n 100000 -c 500 http://localhost:8080/
sudo hping3 -S -p 8080 --flood 127.0.0.1   # SOLO localhost
```

---

## 6. Demo Windows sin Docker (nginx nativo + blindaje)

> ⚙️ **Orquestador automático:** `test-resistencia.ps1` (mismo directorio) hace TODO esto solo: diagnostica herramientas, arranca el objetivo (Docker si puede, si no el demo nginx), lanza línea base → flood → slowloris, comprueba salud post-ataque y genera un informe Markdown en `<staging>\resultados\`. También incluye `script.js` para k6 (prueba escalonada).
>
> ```powershell
> & .\test-resistencia.ps1              # demo nginx (8090) por defecto
> & .\test-resistencia.ps1 -UsarDocker  # staging PHP+MariaDB (requiere engine Linux)
> & .\test-resistencia.ps1 -SoloDiagnostico -PararAlFinal
> ```

Si (como pasa a veces) Docker Desktop no puede levantar el engine Linux porque **no hay WSL2**, puedes practicar igual con el nginx de Scoop sirviendo el staging + las mitigaciones del template:

```powershell
scoop install nginx
# crea C:\Users\zorro\Downloads\staging\nginx-test\conf\nginx.conf
#   (root = web/ del staging, listen 8090, limit_req 20r/s burst=40, limit_conn 20)
New-Item -ItemType Directory -Force -Path logs,temp | Out-Null
Start-Process nginx -ArgumentList "-p","C:/Users/zorro/Downloads/staging/nginx-test/" -WindowStyle Hidden
curl http://127.0.0.1:8090/     # → 200
# ¡usa 127.0.0.1! (el resolver Go no resuelve "localhost" con DNS misconfigurado)

# línea base (200s) y flood (429s — el blindaje frenando):
echo "GET http://127.0.0.1:8090/" > targets.txt
vegeta attack -targets=targets.txt -duration=8s -rate=1000 -workers=100 -output=flood.bin
vegeta report flood.bin
# slowloris:
slowloris 127.0.0.1 -p 8090 -s 100 -ua
# comprobar de nuevo: curl → sigue en 200 (ganaste la defensa)
# parar nginx: nginx -p C:/Users/zorro/Downloads/staging/nginx-test/ -s stop
```

> 📌 `nginx-test/` incluye ya esta config lista para usar (raíz `staging/web`, puerto 8090, límites activos).

---

[⬅ Volver al inicio](README.md)