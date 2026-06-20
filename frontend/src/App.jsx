// frontend/src/App.jsx
import { useState, useEffect } from 'react';
import { registrar, entrar, listarTarefas, criarTarefa, concluirTarefa } from './api';
 
export default function App() {
  const [logado, setLogado] = useState(!!localStorage.getItem('token'));
  const [modo, setModo] = useState('login');
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState('');
  const [tarefas, setTarefas] = useState([]);
  const [novaTarefa, setNovaTarefa] = useState('');
 
  useEffect(() => { if (logado) listarTarefas().then(setTarefas); }, [logado]);
 
  async function enviar() {
    setErro('');
    try {
      if (modo === 'cadastro') { await registrar(email, senha); }
      await entrar(email, senha);
      setLogado(true);
    } catch (e) { setErro(e.message); }
  }
  async function adicionar() {
    if (!novaTarefa.trim()) return;
    await criarTarefa(novaTarefa); setNovaTarefa('');
    setTarefas(await listarTarefas());
  }
  async function alternar(t) {
    await concluirTarefa(t._id, !t.done);
    setTarefas(await listarTarefas());
  }
  function sair() { localStorage.removeItem('token'); setLogado(false); }
 
  // ----- Tela de entrar / cadastrar -----
  if (!logado) return (
    <div className='card'>
      <h1>TaskFlow</h1>
      <h2>{modo === 'login' ? 'Entrar' : 'Criar conta'}</h2>
      <input placeholder='e-mail' value={email} onChange={e => setEmail(e.target.value)} />
      <input placeholder='senha' type='password' value={senha} onChange={e => setSenha(e.target.value)} />
      {erro && <p className='erro'>{erro}</p>}
      <button onClick={enviar}>{modo === 'login' ? 'Entrar' : 'Cadastrar'}</button>
      <a onClick={() => setModo(modo === 'login' ? 'cadastro' : 'login')}>
        {modo === 'login' ? 'Nao tem conta? Cadastre-se' : 'Ja tem conta? Entrar'}
      </a>
    </div>
  );
 
  // ----- Tela de tarefas -----
  return (
    <div className='card'>
      <div className='topo'><h1>Minhas tarefas</h1><button onClick={sair}>Sair</button></div>
      <div className='nova'>
        <input placeholder='Nova tarefa...' value={novaTarefa}
               onChange={e => setNovaTarefa(e.target.value)} />
        <button onClick={adicionar}>Adicionar</button>
      </div>
      <ul>
        {tarefas.map(t => (
          <li key={t._id}>
            <input type='checkbox' checked={t.done} onChange={() => alternar(t)} />
            <span className={t.done ? 'feito' : ''}>{t.title}</span>
          </li>
        ))}
      </ul>
    </div>
  );
}
