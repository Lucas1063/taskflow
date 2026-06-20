// backend/server.js
import express from 'express';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import cors from 'cors';
import { SQSClient, SendMessageCommand } from '@aws-sdk/client-sqs';
 
// ---- Configuracoes (vem de fora, pelo Kubernetes) ----
const PORT = process.env.PORT || 3000;
const MONGO_URL = process.env.MONGO_URL;   // endereco do banco
const JWT_SECRET = process.env.JWT_SECRET; // segredo do cracha de login
const SQS_URL = process.env.SQS_URL;       // endereco da fila de avisos
 
// ---- Liga no banco e na fila ----
await mongoose.connect(MONGO_URL);
const sqs = new SQSClient({ region: 'us-east-1' });
 
// ---- Como guardamos as informacoes no Mongo ----
const User = mongoose.model('User', new mongoose.Schema({
  email: { type: String, unique: true },
  passwordHash: String,
}));
const Task = mongoose.model('Task', new mongoose.Schema({
  userId: String, title: String, done: { type: Boolean, default: false },
}, { timestamps: true }));
 
const app = express();
app.use(cors());
app.use(express.json());
 
// O Kubernetes usa isto para saber se o cerebro esta vivo.
app.get('/healthz', (req, res) => res.send('ok'));
 
// ---- Cadastro ----
app.post('/api/auth/register', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) return res.status(400).json({ error: 'dados faltando' });
  const exists = await User.findOne({ email });
  if (exists) return res.status(409).json({ error: 'email ja cadastrado' });
  const passwordHash = await bcrypt.hash(password, 10); // nunca guardamos a senha pura
  const user = await User.create({ email, passwordHash });
  res.status(201).json({ id: user._id, email });
});
 
// ---- Login ----
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(401).json({ error: 'credenciais invalidas' });
  const ok = await bcrypt.compare(password, user.passwordHash);
  if (!ok) return res.status(401).json({ error: 'credenciais invalidas' });
  const token = jwt.sign({ uid: user._id }, JWT_SECRET, { expiresIn: '8h' });
  res.json({ token, email });
});
 
// ---- Confere o cracha antes das rotas de tarefas ----
function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.replace('Bearer ', '');
  try { req.uid = jwt.verify(token, JWT_SECRET).uid; next(); }
  catch { res.status(401).json({ error: 'nao autenticado' }); }
}
 
// ---- Listar tarefas (direto do Mongo) ----
app.get('/api/tasks', auth, async (req, res) => {
  const tasks = await Task.find({ userId: req.uid }).sort({ createdAt: -1 });
  res.json(tasks);
});
 
// ---- Criar tarefa (e avisar a fila) ----
app.post('/api/tasks', auth, async (req, res) => {
  const task = await Task.create({ userId: req.uid, title: req.body.title });
  await enviarEvento('CRIADA', task);
  res.status(201).json(task);
});
 
// ---- Marcar como feita / desfeita ----
app.patch('/api/tasks/:id', auth, async (req, res) => {
  const task = await Task.findOneAndUpdate(
    { _id: req.params.id, userId: req.uid },
    { done: req.body.done }, { new: true });
  if (task && task.done) await enviarEvento('CONCLUIDA', task);
  res.json(task);
});
 
// ---- Apagar tarefa ----
app.delete('/api/tasks/:id', auth, async (req, res) => {
  await Task.deleteOne({ _id: req.params.id, userId: req.uid });
  res.status(204).end();
});
// ---- Manda o aviso para a fila SQS ----
async function enviarEvento(tipo, task) {
  if (!SQS_URL) return;
  const corpo = JSON.stringify({ tipo, titulo: task.title, taskId: task._id });
  await sqs.send(new SendMessageCommand({ QueueUrl: SQS_URL, MessageBody: corpo }));
}
 
app.listen(PORT, () => console.log('Backend ouvindo na porta ' + PORT));
