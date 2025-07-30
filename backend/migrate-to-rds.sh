#!/bin/bash

# Script para migrar do SQLite para RDS PostgreSQL

echo "=== Migração SQLite para RDS PostgreSQL ==="

# 1. Backup do SQLite atual
echo "1. Fazendo backup do SQLite..."
if [ -f "tasks.db" ]; then
    cp tasks.db tasks_sqlite_backup_$(date +%Y%m%d_%H%M%S).db
    echo "✅ Backup criado"
else
    echo "⚠️  Arquivo SQLite não encontrado"
fi

# 2. Instalar dependências RDS
echo "2. Instalando dependências PostgreSQL..."
pip3 install psycopg2-binary asyncpg

# 3. Testar conexão RDS (se configurado)
echo "3. Testando conexão RDS..."
python3 -c "
import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv()
DATABASE_URL = os.getenv('DATABASE_URL')

if DATABASE_URL and DATABASE_URL.startswith('postgresql'):
    try:
        engine = create_engine(DATABASE_URL)
        with engine.connect() as conn:
            result = conn.execute(text('SELECT 1'))
            print('✅ Conexão RDS OK')
    except Exception as e:
        print(f'❌ Erro conexão RDS: {e}')
else:
    print('⚠️  RDS não configurado, usando SQLite')
"

# 4. Criar tabelas no RDS
echo "4. Criando tabelas no RDS..."
python3 -c "
from main import Base, engine
try:
    Base.metadata.create_all(bind=engine)
    print('✅ Tabelas criadas com sucesso')
except Exception as e:
    print(f'❌ Erro criando tabelas: {e}')
"

echo "=== Migração concluída ==="
echo "Para usar RDS:"
echo "1. Configure DATABASE_URL no .env"
echo "2. Reinicie a aplicação"
echo "3. Verifique se está funcionando"
