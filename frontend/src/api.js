const base = '/api';

function headers() {
  const t = localStorage.getItem('token');
  return {
    'Content-Type': 'application/json',
    ...(t ? { Authorization: 'Bearer ' + t } : {})
  };
}

// Helper central: trata respostas não-ok de forma consistente,
// anexando o status no erro pra quem chama poder decidir o que fazer.
async function tratarResposta(r) {
  if (!r.ok) {
    let mensagem = 'Erro na requisição';
    try {
      const data = await r.json();
      mensagem = data.error || mensagem;
    } catch (_) {
      // corpo não era JSON, ignora
    }
    const erro = new Error(mensagem);
    erro.status = r.status;
    throw erro;
  }
  return r.json();
}

export async function registrar(email, password) {
  const r = await fetch(base + '/auth/register', {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ email, password })
  });
  if (!r.ok) {
    const data = await r.json().catch(() => ({}));
    throw new Error(data.error || 'Falha ao registrar');
  }
}

export async function entrar(email, password) {
  const r = await fetch(base + '/auth/login', {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ email, password })
  });
  if (!r.ok) {
    const data = await r.json().catch(() => ({}));
    throw new Error(data.error || 'Falha ao entrar');
  }
  const data = await r.json();
  localStorage.setItem('token', data.token);
}

export const listarTarefas = () =>
  fetch(base + '/tasks', { headers: headers() }).then(tratarResposta);

export const criarTarefa = (title) =>
  fetch(base + '/tasks', {
    method: 'POST', headers: headers(),
    body: JSON.stringify({ title })
  }).then(tratarResposta);

export const concluirTarefa = (id, done) =>
  fetch(base + '/tasks/' + id, {
    method: 'PATCH', headers: headers(),
    body: JSON.stringify({ done })
  }).then(tratarResposta);

// NOVA FUNÇÃO: Excluir tarefa
export const deletarTarefa = (id) =>
  fetch(base + '/tasks/' + id, {
    method: 'DELETE',
    headers: headers()
  }).then(tratarResposta);