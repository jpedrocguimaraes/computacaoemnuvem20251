# 🗄️ PASSO A PASSO: PostgreSQL no EC2

## ⚠️ IMPORTANTE: Esta opção é mais simples mas pode ter menor pontuação AWS

### FASE 1: INSTALAR POSTGRESQL NO EC2

#### 1.1 Conectar no EC2:
```bash
ssh -i sua-chave.pem ec2-user@SEU_IP_EC2
```

#### 1.2 Instalar PostgreSQL:
```bash
# Atualizar sistema
sudo yum update -y

# Instalar PostgreSQL
sudo yum install -y postgresql15-server postgresql15

# Inicializar banco
sudo postgresql-setup --initdb

# Iniciar e habilitar serviço
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl status postgresql
```

#### 1.3 Configurar usuário e banco:
```bash
# Trocar para usuário postgres
sudo -u postgres psql

# No prompt do PostgreSQL:
CREATE USER tasks_user WITH PASSWORD 'TasksPassword123!';
CREATE DATABASE tasks_database OWNER tasks_user;
GRANT ALL PRIVILEGES ON DATABASE tasks_database TO tasks_user;
\q
```

#### 1.4 Configurar autenticação:
```bash
# Editar pg_hba.conf
sudo nano /var/lib/pgsql/data/pg_hba.conf

# Adicionar linha (antes das outras):
local   tasks_database    tasks_user                    md5

# Reiniciar PostgreSQL
sudo systemctl restart postgresql
```

### FASE 2: CONFIGURAR APLICAÇÃO

#### 2.1 Atualizar .env:
```bash
cd /home/ec2-user/app/backend
nano .env

# Conteúdo:
DATABASE_URL=postgresql://tasks_user:TasksPassword123!@localhost:5432/tasks_database
ENVIRONMENT=production
PORT=8000
```

#### 2.2 Instalar dependências:
```bash
pip3 install psycopg2-binary asyncpg
```

#### 2.3 Testar e criar tabelas:
```bash
python3 setup_postgresql.py
```

### FASE 3: ATUALIZAR DEPLOY

#### 3.1 O deploy script já suporta!
O script atual já instala as dependências PostgreSQL.

#### 3.2 Testar aplicação:
```bash
pm2 restart todo-backend
pm2 logs todo-backend
curl http://localhost:8000/health
```

## 📊 COMPARAÇÃO FINAL:

| **Aspecto** | **RDS** | **EC2 PostgreSQL** |
|-------------|---------|-------------------|
| **Pontuação AWS** | 🏆 Máxima | ⚠️ Menor |
| **Complexidade** | Média | Baixa |
| **Backup** | Automático | Manual |
| **Escalabilidade** | Fácil | Limitada |
| **Custo AWS Academy** | Gratuito* | Gratuito |

*AWS Academy tem créditos limitados, mas RDS free tier geralmente cabe no limite.
