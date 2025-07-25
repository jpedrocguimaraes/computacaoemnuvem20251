import React, { useState, useEffect } from 'react';
import axios from 'axios';

// Configuração da base URL da API
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';
const api = axios.create({
  baseURL: API_BASE_URL,
});

function App() {
  const [tasks, setTasks] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [formData, setFormData] = useState({
    title: '',
    description: ''
  });

  // Carregar tarefas quando o componente monta
  useEffect(() => {
    loadTasks();
  }, []);

  const loadTasks = async () => {
    try {
      setLoading(true);
      const response = await api.get('/tasks/');
      setTasks(response.data);
      setError('');
    } catch (err) {
      setError('Erro ao carregar tarefas. Verifique se o backend está rodando.');
      console.error('Erro ao carregar tarefas:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.title.trim()) {
      setError('O título da tarefa é obrigatório');
      return;
    }

    try {
      await api.post('/tasks/', formData);
      setFormData({ title: '', description: '' });
      setError('');
      loadTasks();
    } catch (err) {
      setError('Erro ao criar tarefa');
      console.error('Erro ao criar tarefa:', err);
    }
  };

  const toggleTaskComplete = async (taskId, completed) => {
    try {
      await api.put(`/tasks/${taskId}`, { completed: !completed });
      loadTasks();
    } catch (err) {
      setError('Erro ao atualizar tarefa');
      console.error('Erro ao atualizar tarefa:', err);
    }
  };

  const deleteTask = async (taskId) => {
    if (window.confirm('Tem certeza que deseja deletar esta tarefa?')) {
      try {
        await api.delete(`/tasks/${taskId}`);
        loadTasks();
      } catch (err) {
        setError('Erro ao deletar tarefa');
        console.error('Erro ao deletar tarefa:', err);
      }
    }
  };

  return (
    <div className="container">
      <div className="header">
        <h1>📝 Lista de Tarefas</h1>
        <p>Gerencie suas tarefas de forma simples e eficiente</p>
      </div>

      {error && <div className="error">{error}</div>}

      <div className="task-form">
        <h3>Adicionar Nova Tarefa</h3>
        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label htmlFor="title">Título *</label>
            <input
              type="text"
              id="title"
              name="title"
              value={formData.title}
              onChange={handleInputChange}
              placeholder="Digite o título da tarefa"
              required
            />
          </div>
          <div className="form-group">
            <label htmlFor="description">Descrição</label>
            <textarea
              id="description"
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              placeholder="Digite uma descrição (opcional)"
            />
          </div>
          <button type="submit" className="btn">
            Adicionar Tarefa
          </button>
        </form>
      </div>

      <div className="task-list">
        {loading ? (
          <div className="loading">Carregando tarefas...</div>
        ) : tasks.length === 0 ? (
          <div className="empty-state">
            <p>Nenhuma tarefa encontrada.</p>
            <p>Que tal adicionar a primeira?</p>
          </div>
        ) : (
          tasks.map((task) => (
            <div key={task.id} className="task-item">
              <div className="task-content">
                <h4 className={`task-title ${task.completed ? 'completed' : ''}`}>
                  {task.title}
                </h4>
                {task.description && (
                  <p className="task-description">{task.description}</p>
                )}
                <small>
                  Criada em: {new Date(task.created_at).toLocaleDateString('pt-BR')}
                </small>
              </div>
              <div className="task-actions">
                <button
                  onClick={() => toggleTaskComplete(task.id, task.completed)}
                  className={`btn ${task.completed ? 'btn-success' : ''}`}
                >
                  {task.completed ? '✓ Concluída' : '○ Marcar como Concluída'}
                </button>
                <button
                  onClick={() => deleteTask(task.id)}
                  className="btn btn-danger"
                >
                  🗑 Deletar
                </button>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
}

export default App;
