// frontend/src/api.js
const base = '/api';
function headers() {
  const t = localStorage.getItem('token');
  return { 'Content-Type': 'application/json',
           ...(t ? { Authorization: 'Bearer ' + t } : {}) };
}
export async function registrar(email, password) {
  const r = await fetch(base + '/auth/register', { method: 'POST',
    headers: headers(), body: JSON.stringify({ email, password }) });
  if (!r.ok) throw new Error((await r.json()).error);
}
export async function entrar(email, password) {
  const r = await fetch(base + '/auth/login', { method: 'POST',
    headers: headers(), body: JSON.stringify({ email, password }) });
  if (!r.ok) throw new Error((await r.json()).error);
  const data = await r.json();
  localStorage.setItem('token', data.token);
}
export const listarTarefas = () =>
  fetch(base + '/tasks', { headers: headers() }).then(r => r.json());
export const criarTarefa = (title) =>
  fetch(base + '/tasks', { method: 'POST', headers: headers(),
        body: JSON.stringify({ title }) });
export const concluirTarefa = (id, done) =>
  fetch(base + '/tasks/' + id, { method: 'PATCH', headers: headers(),
        body: JSON.stringify({ done }) });
