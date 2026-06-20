import { useState, useEffect } from 'react';
import { registrar, entrar, listarTarefas, criarTarefa, concluirTarefa, deletarTarefa } from './api';
import './App.css'; // <-- Importando nosso novo visual

export default function App() {
const [logado, setLogado] = useState(true);
  const [modo, setModo] = useState('login');
  const [email, setEmail] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState('');
  const [tarefas, setTarefas] = useState([]);
  const [novaTarefa, setNovaTarefa] = useState('');
  

  useEffect(() => { 
    if (logado) listarTarefas().then(setTarefas); 
  }, [logado]);

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
    await criarTarefa(novaTarefa); 
    setNovaTarefa('');
    setTarefas(await listarTarefas());
  }

  async function alternar(t) {
    await concluirTarefa(t._id, !t.done);
    setTarefas(await listarTarefas());
  }

  // NOVA FUNÇÃO: Aciona a API e recarrega a lista
  async function remover(id) {
    await deletarTarefa(id);
    setTarefas(await listarTarefas());
  }

  function sair() { 
    localStorage.removeItem('token'); 
    setLogado(false); 
    
  }

  // ----- Tela de entrar / cadastrar -----
  if (!logado) return (
    <div className='container'>
      <div className='card auth-card'>
        <h1 className='logo'>TaskFlow</h1>
        <h2>{modo === 'login' ? 'Bem-vindo de volta' : 'Crie sua conta'}</h2>
        
        <div className='form-group'>
          <input placeholder='E-mail' type='email' value={email} onChange={e => setEmail(e.target.value)} />
          <input placeholder='Senha' type='password' value={senha} onChange={e => setSenha(e.target.value)} />
        </div>
        
        {erro && <p className='erro'>{erro}</p>}
        
        <button className='btn-primary full-width' onClick={enviar}>
          {modo === 'login' ? 'Entrar' : 'Cadastrar'}
        </button>
        
        <button className='btn-link' onClick={() => setModo(modo === 'login' ? 'cadastro' : 'login')}>
          {modo === 'login' ? 'Não tem conta? Cadastre-se' : 'Já tem conta? Entrar'}
        </button>
      </div>
    </div>
  );

  // ----- Tela de tarefas -----
  return (
    <div className='container'>
      <div className='card tasks-card'>
        <div className='topo'>
          <h1>Minhas tarefas</h1>
          <button className='btn-outline' onClick={sair}>Sair</button>
        </div>
        
        <div className='nova-tarefa'>
          <input 
            placeholder='O que você precisa fazer hoje?' 
            value={novaTarefa}
            onChange={e => setNovaTarefa(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && adicionar()} // Adiciona ao apertar Enter
          />
          <button className='btn-primary' onClick={adicionar}>Adicionar</button>
        </div>
        
        {tarefas.length === 0 ? (
          <p className='empty-state'>Você não tem nenhuma tarefa pendente. Oba! 🎉</p>
        ) : (
          <ul className='lista-tarefas'>
            {tarefas.map(t => (
              <li key={t._id} className={`tarefa-item ${t.done ? 'concluida' : ''}`}>
                <label className='tarefa-conteudo'>
                  <input type='checkbox' checked={t.done} onChange={() => alternar(t)} />
                  <span className='checkmark'></span>
                  <span className='texto'>{t.title}</span>
                </label>
                <button className='btn-excluir' onClick={() => remover(t._id)} title='Excluir tarefa'>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <path d="M3 6h18"></path>
                    <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"></path>
                    <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"></path>
                  </svg>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
