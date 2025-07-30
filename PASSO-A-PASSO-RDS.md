# 🗄️ PASSO A PASSO: RDS PostgreSQL Setup

## ✅ CHECKLIST COMPLETO:

### FASE 1: CRIAR RDS POSTGRESQL
- [ ] 1.1 Acessar AWS Academy
- [ ] 1.2 Criar instância RDS PostgreSQL
- [ ] 1.3 Configurar Security Group
- [ ] 1.4 Anotar endpoint de conexão

### FASE 2: CONFIGURAR APLICAÇÃO
- [ ] 2.1 Atualizar .env com credenciais RDS
- [ ] 2.2 Testar conexão local
- [ ] 2.3 Migrar dados (se houver)

### FASE 3: ATUALIZAR CI/CD
- [ ] 3.1 Adicionar secrets do banco no GitHub
- [ ] 3.2 Testar deploy automático
- [ ] 3.3 Verificar aplicação funcionando

### FASE 4: DOCUMENTAÇÃO
- [ ] 4.1 Atualizar README.md
- [ ] 4.2 Documentar configuração do banco
- [ ] 4.3 Gravar vídeo demonstrativo

---

## 📋 FASE 1: CRIAR RDS POSTGRESQL

### 1.1 Acessar AWS Academy:
1. Entre no AWS Academy
2. Clique em "Start Lab"
3. Aguarde o indicador ficar verde
4. Clique em "AWS" para acessar o console

### 1.2 Criar RDS PostgreSQL:

#### No Console AWS:
1. **Serviços** → **RDS** → **Create Database**

2. **Choose database creation method:**
   - ✅ Standard create

3. **Engine options:**
   - ✅ PostgreSQL
   - Version: PostgreSQL 15.4-R2 (mais recente disponível)

4. **Templates:**
   - ✅ Free tier (para não ter custos)

5. **Credentials Settings:**
   - **DB instance identifier**: `tasks-database`
   - **Master username**: `tasks_admin`
   - **Master password**: `TasksPassword123!`
   - **Confirm password**: `TasksPassword123!`

6. **Instance configuration:**
   - **DB instance class**: db.t3.micro (Free tier)

7. **Storage:**
   - **Storage type**: General Purpose SSD (gp2)
   - **Allocated storage**: 20 GB
   - ❌ Enable storage autoscaling (desmarcado)

8. **Connectivity:**
   - **Compute resource**: Don't connect to an EC2 compute resource
   - **VPC**: Default VPC
   - **DB Subnet group**: default
   - **Public access**: No
   - **VPC security group**: Create new
   - **New VPC security group name**: `rds-postgresql-sg`

9. **Database authentication:**
   - ✅ Password authentication

10. **Additional configuration:**
    - **Initial database name**: `tasks_db`
    - **Backup retention period**: 7 days
    - ✅ Enable encryption

11. **Clique em "Create database"**

### 1.3 Configurar Security Group:

#### Enquanto o RDS é criado (leva ~10-15 min):
1. **EC2** → **Security Groups**
2. Encontre seu **Security Group do EC2** (anote o ID: sg-xxxxx)
3. Clique no **Security Group RDS** criado (`rds-postgresql-sg`)
4. **Inbound rules** → **Edit inbound rules** → **Add rule**
   - **Type**: PostgreSQL
   - **Protocol**: TCP
   - **Port Range**: 5432
   - **Source**: Custom → Cole o ID do SG do EC2 (sg-xxxxx)
   - **Description**: Allow PostgreSQL from EC2
5. **Save rules**

### 1.4 Anotar Endpoint:
1. **RDS** → **Databases** → **tasks-database**
2. Aguarde status "Available"
3. **Connectivity & security** → Copie o **Endpoint**
4. Exemplo: `tasks-database.c9akl7j2k3l4.us-east-1.rds.amazonaws.com`

---

## 📋 FASE 2: CONFIGURAR APLICAÇÃO

### 2.1 Atualizar .env:
```bash
# No seu computador local, edite backend/.env:
DATABASE_URL=postgresql://tasks_admin:TasksPassword123!@tasks-database.c9akl7j2k3l4.us-east-1.rds.amazonaws.com:5432/tasks_db
ENVIRONMENT=production
PORT=8000
```

### 2.2 Testar conexão local:
```bash
cd backend
# O código já cria as tabelas automaticamente!
# Esta linha no main.py faz tudo: Base.metadata.create_all(bind=engine)
python setup_postgresql.py
```

**✅ IMPORTANTE**: Seu código já instancia as tabelas automaticamente através da linha:
```python
Base.metadata.create_all(bind=engine)
```

### 2.3 Verificar criação das tabelas:
```bash
# As tabelas serão criadas automaticamente na primeira conexão!
python3 -c "
from main import engine
from sqlalchemy import text
with engine.connect() as conn:
    result = conn.execute(text(\"SELECT table_name FROM information_schema.tables WHERE table_schema = 'public'\"))
    tables = [row[0] for row in result]
    print(f'Tabelas criadas: {tables}')
"
```

---

## 📋 FASE 3: ATUALIZAR CI/CD

### 3.1 Adicionar secrets no GitHub:
1. **GitHub** → **Seu repositório** → **Settings** → **Secrets and variables** → **Actions**
2. **New repository secret**:
   - **Name**: `DATABASE_URL`
   - **Value**: `postgresql://tasks_admin:TasksPassword123!@tasks-database.c9akl7j2k3l4.us-east-1.rds.amazonaws.com:5432/tasks_db`

### 3.2 Atualizar deploy script:
O script já está preparado para RDS!

### 3.3 Testar deploy:
```bash
git add .
git commit -m "Configure PostgreSQL RDS"
git push origin main
```

---

## 📋 FASE 4: VERIFICAÇÃO

### 4.1 Verificar funcionamento:
1. **GitHub Actions** deve executar sem erros
2. Aplicação deve estar acessível: `http://SEU_IP_EC2`
3. API deve responder: `http://SEU_IP_EC2/docs`

### 4.2 Testar CRUD:
1. Criar uma tarefa
2. Listar tarefas
3. Marcar como concluída
4. Deletar tarefa

---

## 🎯 PONTOS DE AVALIAÇÃO CONTEMPLADOS:

✅ **Funcionalidade (2 pts)**: App completo com persistência PostgreSQL
✅ **CI/CD (3 pts)**: Pipeline robusto com deploy automático
✅ **AWS (2 pts)**: Uso adequado de RDS + EC2
✅ **Documentação (1 pt)**: README completo

## 🚨 TROUBLESHOOTING COMUM:

### Connection timeout:
- Verificar Security Groups
- Verificar VPC/Subnets

### Authentication failed:
- Verificar credenciais no .env
- Verificar se banco foi criado

### Database não existe:
- Verificar se "Initial database name" foi preenchido
- Criar manualmente se necessário

## 📞 COMANDOS ÚTEIS:

### Testar conexão do EC2:
```bash
# Conectar via SSH no EC2
ssh -i sua-chave.pem ec2-user@SEU_IP_EC2

# Testar conexão PostgreSQL
cd /home/ec2-user/app/backend
python3 setup_postgresql.py
```

### Ver logs da aplicação:
```bash
pm2 logs todo-backend
```

### Verificar status do banco:
```bash
python3 -c "
from main import SessionLocal
from sqlalchemy import text
db = SessionLocal()
result = db.execute(text('SELECT version()'))
print(f'PostgreSQL: {result.scalar()}')
db.close()
"
```
