# ===== CONFIGURAÇÃO RDS POSTGRESQL =====

## 1. CRIAR RDS NO AWS CONSOLE:

### Configurações básicas:
- **Engine**: PostgreSQL 15.x
- **Template**: Production (ou Free tier para teste)
- **DB Instance**: db.t3.micro (Free tier) ou db.t3.small (Produção)
- **Storage**: 20-100 GB GP3

### Configurações de conectividade:
- **VPC**: Mesma VPC do EC2
- **Public Access**: No (apenas EC2 acessa)
- **VPC Security Group**: Criar novo ou usar existente
- **Port**: 5432 (padrão PostgreSQL)

### Configurações de autenticação:
- **Database name**: tasks_database
- **Master username**: tasks_admin
- **Master password**: SuaSenhaSegura123!

### Configurações adicionais:
- **Backup retention**: 7 dias
- **Monitoring**: Enhanced monitoring habilitado
- **Encryption**: Habilitado
- **Auto minor version upgrade**: Sim

## 2. CONFIGURAR SECURITY GROUP:

### Criar regra de entrada:
- **Type**: PostgreSQL
- **Protocol**: TCP  
- **Port Range**: 5432
- **Source**: Security Group do EC2
- **Description**: Allow PostgreSQL from EC2

## 3. CONFIGURAR VARIÁVEIS DE AMBIENTE:

### No arquivo .env do EC2:
```bash
# PostgreSQL RDS
DATABASE_URL=postgresql://tasks_admin:SuaSenhaSegura123!@tasks-db.cluster-xyz.us-east-1.rds.amazonaws.com:5432/tasks_database
ENVIRONMENT=production
PORT=8000
```

## 4. TESTAR CONEXÃO:

### Do EC2 para RDS:
```bash
# Instalar cliente PostgreSQL
sudo yum install -y postgresql15

# Testar conexão
psql -h tasks-db.cluster-xyz.us-east-1.rds.amazonaws.com -U tasks_admin -d tasks_database

# Ou usando Python
python3 setup_postgresql.py
```

## 5. CUSTOS ESTIMADOS (us-east-1):

### db.t3.micro (Free tier elegível):
- **Instância**: $0.017/hora = ~$12.50/mês (após free tier)
- **Storage**: $0.115/GB/mês = ~$2.30/mês (20GB)
- **Backup**: Gratuito (até 20GB)
- **Total**: ~$15/mês

### db.t3.small (Produção pequena):
- **Instância**: $0.034/hora = ~$25/mês
- **Storage**: $0.115/GB/mês = ~$5.75/mês (50GB)
- **Total**: ~$31/mês

## 6. OTIMIZAÇÕES DE PERFORMANCE:

### Configurações recomendadas:
```python
# No main.py
engine = create_engine(
    DATABASE_URL,
    pool_size=20,              # Conexões no pool
    max_overflow=30,           # Conexões extras
    pool_pre_ping=True,        # Verificar conexões
    pool_recycle=3600,         # Reciclar a cada hora
    echo=False                 # Desabilitar logs SQL em produção
)
```

### Monitoramento:
- CloudWatch metrics habilitado
- Performance Insights habilitado
- Log de queries lentas > 1s

## 7. BACKUP E RECUPERAÇÃO:

### Automático:
- Backup diário automático (7 dias retenção)
- Point-in-time recovery

### Manual:
```bash
# Criar snapshot manual
aws rds create-db-snapshot \
    --db-instance-identifier tasks-db \
    --db-snapshot-identifier tasks-manual-backup-$(date +%Y%m%d)
```

## 8. SEGURANÇA:

### Configurações obrigatórias:
- ✅ Encryption at rest habilitado
- ✅ SSL/TLS obrigatório
- ✅ VPC privada (sem acesso público)
- ✅ Security Groups restritivos
- ✅ Senhas complexas
- ✅ Rotação de credenciais (AWS Secrets Manager)

## 9. MIGRAÇÃO DE DADOS:

### Do SQLite para PostgreSQL:
```bash
# 1. Executar script de migração
python3 migrate_data.py

# 2. Verificar dados migrados
python3 -c "
from main import SessionLocal
from sqlalchemy import text
db = SessionLocal()
result = db.execute(text('SELECT COUNT(*) FROM tasks'))
print(f'Total tarefas: {result.scalar()}')
db.close()
"
```

## 10. TROUBLESHOOTING:

### Erros comuns:
1. **Connection timeout**: Verificar Security Groups
2. **Authentication failed**: Verificar usuário/senha
3. **Database não existe**: Criar database no RDS
4. **SSL required**: Adicionar `?sslmode=require` na URL

### Logs úteis:
```bash
# Logs da aplicação
pm2 logs todo-backend

# Logs do PostgreSQL (via CloudWatch)
aws logs get-log-events --log-group-name /aws/rds/instance/tasks-db/postgresql
```
