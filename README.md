# 📝 Lista de Tarefas - Aplicação Web com CI/CD

## 👥 Integrantes da Dupla
- [Seu Nome]
- [Nome do Parceiro]

## 📖 Descrição da Aplicação

Esta é uma aplicação web simples de lista de tarefas (To-Do List) desenvolvida como parte do trabalho final da disciplina de Computação em Nuvem. A aplicação permite aos usuários:

- ✅ Criar novas tarefas com título e descrição
- 📋 Visualizar todas as tarefas
- ✔️ Marcar tarefas como concluídas
- 🗑️ Deletar tarefas
- 💾 Persistência de dados em banco relacional

## 🛠️ Tecnologias Utilizadas

### Backend
- **Linguagem**: Python 3.9+
- **Framework**: FastAPI
- **Banco de Dados**: SQLite (relacional)
- **ORM**: SQLAlchemy
- **Servidor ASGI**: Uvicorn

### Frontend
- **Framework**: React 18
- **Linguagem**: JavaScript (ES6+)
- **HTTP Client**: Axios
- **Build Tool**: Create React App

### Infraestrutura AWS
- **Compute**: Amazon EC2 (Amazon Linux 2)
- **Web Server**: Nginx (reverse proxy)
- **Process Manager**: PM2

### CI/CD e Versionamento
- **Repositório**: GitHub (privado)
- **CI/CD**: GitHub Actions
- **Deploy**: Automatizado para EC2

## 🏗️ Arquitetura da Aplicação

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│                 │    │                 │    │                 │
│   Frontend      │────│   Nginx         │────│   Backend       │
│   (React)       │    │   (Reverse      │    │   (FastAPI)     │
│   Port: 3000    │    │   Proxy)        │    │   Port: 8000    │
│                 │    │   Port: 80      │    │                 │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                                        │
                                                        │
                                               ┌─────────────────┐
                                               │                 │
                                               │   SQLite DB     │
                                               │   (tasks.db)    │
                                               │                 │
                                               └─────────────────┘
```

## 🚀 Configuração e Execução Local

### Pré-requisitos
- Python 3.9+
- Node.js 18+
- npm ou yarn

### Backend
1. Navegue para a pasta do backend:
```bash
cd backend
```

2. Crie um ambiente virtual:
```bash
python -m venv venv
source venv/bin/activate  # No Windows: venv\Scripts\activate
```

3. Instale as dependências:
```bash
pip install -r requirements.txt
```

4. Execute a aplicação:
```bash
python main.py
```

O backend estará disponível em: http://localhost:8000
Documentação da API: http://localhost:8000/docs

### Frontend
1. Navegue para a pasta do frontend:
```bash
cd frontend
```

2. Instale as dependências:
```bash
npm install
```

3. Execute a aplicação:
```bash
npm start
```

O frontend estará disponível em: http://localhost:3000

## 🔄 Pipeline CI/CD

O pipeline é executado automaticamente a cada push na branch `main` e consiste nas seguintes etapas:

### Etapa de Teste (Test Job)
1. **Setup do Ambiente**: Configura Python 3.9 e Node.js 18
2. **Instalação de Dependências**: 
   - Backend: `pip install -r requirements.txt`
   - Frontend: `npm install`
3. **Testes**:
   - Backend: Verifica importações e sintaxe
   - Frontend: Build de produção (`npm run build`)

### Etapa de Deploy (Deploy Job)
1. **Conexão SSH**: Conecta ao servidor EC2 usando chave privada
2. **Backup**: Realiza backup do banco de dados atual
3. **Atualização do Código**: Envia novo código para o servidor
4. **Deploy Automatizado**: Executa script de deploy (`deploy.sh`)
5. **Verificação**: Testa se a aplicação está funcionando (health check)

### Variáveis de Ambiente Necessárias (GitHub Secrets)
- `EC2_SSH_KEY`: Chave privada SSH para acesso ao EC2
- `EC2_HOST`: IP público ou DNS da instância EC2
- `EC2_USER`: Usuário SSH (geralmente `ec2-user`)

## 🌐 Acesso à Aplicação na AWS

### URL da Aplicação
A aplicação estará disponível no IP público da sua instância EC2:
- **Frontend**: `http://[SEU-IP-EC2]`
- **API**: `http://[SEU-IP-EC2]/docs`

### Configuração da Instância EC2
1. **Tipo de Instância**: t2.micro (elegível para free tier)
2. **AMI**: Amazon Linux 2
3. **Security Group**: 
   - HTTP (80): 0.0.0.0/0
   - HTTPS (443): 0.0.0.0/0
   - SSH (22): Seu IP
4. **Storage**: 8 GB gp2

## 📁 Estrutura do Projeto

```
├── .github/
│   └── workflows/
│       └── deploy.yml          # Pipeline CI/CD
├── backend/
│   ├── main.py                 # Aplicação FastAPI
│   ├── requirements.txt        # Dependências Python
│   └── .env                    # Variáveis de ambiente
├── frontend/
│   ├── public/
│   │   └── index.html         # HTML principal
│   ├── src/
│   │   ├── App.js             # Componente principal React
│   │   ├── index.js           # Ponto de entrada
│   │   └── index.css          # Estilos
│   ├── package.json           # Dependências Node.js
│   └── .env.production        # Variáveis de produção
├── deploy.sh                  # Script de deploy
├── README.md                  # Documentação
└── projeto.txt               # Especificação do trabalho
```

## 🔧 Comandos Úteis

### Desenvolvimento Local
```bash
# Executar backend
cd backend && python main.py

# Executar frontend
cd frontend && npm start

# Build de produção do frontend
cd frontend && npm run build
```

### Gerenciamento no Servidor (PM2)
```bash
# Ver status das aplicações
pm2 status

# Ver logs
pm2 logs todo-backend

# Reiniciar aplicação
pm2 restart todo-backend

# Parar aplicação
pm2 stop todo-backend
```

### Nginx
```bash
# Verificar status
sudo systemctl status nginx

# Reiniciar
sudo systemctl restart nginx

# Ver logs
sudo tail -f /var/log/nginx/error.log
```

## 🐛 Troubleshooting

### Problemas Comuns

1. **API não responde**:
   - Verifique se o backend está rodando: `pm2 status`
   - Verifique logs: `pm2 logs todo-backend`

2. **Frontend não carrega**:
   - Verifique se nginx está rodando: `sudo systemctl status nginx`
   - Verifique configuração: `sudo nginx -t`

3. **Banco de dados com erro**:
   - Verifique permissões do arquivo: `ls -la backend/tasks.db`
   - Recriar banco: `cd backend && python -c "from main import Base, engine; Base.metadata.create_all(bind=engine)"`

4. **Deploy falha**:
   - Verifique secrets do GitHub
   - Verifique conectividade SSH
   - Verifique logs do GitHub Actions

## 📊 Endpoints da API

| Método | Endpoint | Descrição |
|--------|----------|-----------|
| GET | `/` | Status da API |
| GET | `/health` | Health check |
| GET | `/tasks/` | Listar todas as tarefas |
| POST | `/tasks/` | Criar nova tarefa |
| GET | `/tasks/{id}` | Obter tarefa específica |
| PUT | `/tasks/{id}` | Atualizar tarefa |
| DELETE | `/tasks/{id}` | Deletar tarefa |

## 📄 Licença

Este projeto foi desenvolvido para fins educacionais como parte do trabalho final da disciplina de Computação em Nuvem.

---

**Nota**: Lembre-se de configurar corretamente as variáveis de ambiente e secrets antes do deploy!
