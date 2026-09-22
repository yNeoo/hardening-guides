// k6 — prueba escalonada contra el staging local
// Uso:   k6 run script.js
// Objetivo: ver dónde cede el servidor subiendo VUs de a poco.
// Nota: con el blindaje activo verás muchos 429 (el limit_req frenando) → el
//       throughput real se queda plano: es el techo de la config, no de CPU.
import http from "k6/http";
import { check } from "k6";

export const options = {
  stages: [
    { duration: "20s", target: 100 },   // VUs
    { duration: "20s", target: 500 },
    { duration: "30s", target: 2000 },
    { duration: "20s", target: 0 },
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"],
    // 429 del blindaje no cuenta como fallo duro aquí:
    http_req_failed: ["rate<0.95"],
  },
};

export default function () {
  const r = http.get("http://127.0.0.1:8090/");
  check(r, {
    "respuesta (200 o 429 del blindaje)": (res) =>
      res.status === 200 || res.status === 429,
  });
}