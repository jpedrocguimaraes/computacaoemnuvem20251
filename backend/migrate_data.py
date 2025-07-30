#!/usr/bin/env python3
"""
Script para migrar dados do SQLite para RDS PostgreSQL
"""
import os
import sys
from datetime import datetime
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

# Carregar variáveis de ambiente
load_dotenv()

def migrate_data():
    """Migra dados do SQLite para PostgreSQL"""
    
    # URLs de conexão
    sqlite_url = "sqlite:///./tasks.db"
    postgres_url = os.getenv("DATABASE_URL")
    
    if not postgres_url or not postgres_url.startswith("postgresql"):
        print("❌ URL do PostgreSQL não configurada no .env")
        sys.exit(1)
    
    print("=== Iniciando Migração de Dados ===")
    
    try:
        # Conectar aos bancos
        sqlite_engine = create_engine(sqlite_url)
        postgres_engine = create_engine(postgres_url)
        
        SQLiteSession = sessionmaker(bind=sqlite_engine)
        PostgresSession = sessionmaker(bind=postgres_engine)
        
        sqlite_session = SQLiteSession()
        postgres_session = PostgresSession()
        
        # Verificar se há dados no SQLite
        result = sqlite_session.execute(text("SELECT COUNT(*) FROM tasks"))
        count = result.scalar()
        
        if count == 0:
            print("⚠️  Nenhuma tarefa encontrada no SQLite")
            return
        
        print(f"📋 Encontradas {count} tarefas no SQLite")
        
        # Buscar dados do SQLite
        tasks = sqlite_session.execute(text("""
            SELECT id, title, description, completed, created_at 
            FROM tasks ORDER BY id
        """)).fetchall()
        
        # Limpar tabela PostgreSQL (opcional)
        postgres_session.execute(text("DELETE FROM tasks"))
        postgres_session.commit()
        
        # Inserir dados no PostgreSQL
        for task in tasks:
            postgres_session.execute(text("""
                INSERT INTO tasks (title, description, completed, created_at)
                VALUES (:title, :description, :completed, :created_at)
            """), {
                'title': task.title,
                'description': task.description,
                'completed': task.completed,
                'created_at': task.created_at
            })
        
        postgres_session.commit()
        
        # Verificar migração
        result = postgres_session.execute(text("SELECT COUNT(*) FROM tasks"))
        migrated_count = result.scalar()
        
        print(f"✅ Migração concluída: {migrated_count} tarefas migradas")
        
        # Fechar conexões
        sqlite_session.close()
        postgres_session.close()
        
    except Exception as e:
        print(f"❌ Erro na migração: {e}")
        sys.exit(1)

if __name__ == "__main__":
    migrate_data()
