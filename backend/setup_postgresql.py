#!/usr/bin/env python3
"""
Script para configurar e testar PostgreSQL
"""
import os
import sys
import subprocess
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv

def install_postgresql_deps():
    """Instala dependências PostgreSQL"""
    print("📦 Instalando dependências PostgreSQL...")
    try:
        subprocess.run([sys.executable, "-m", "pip", "install", "psycopg2-binary", "asyncpg"], check=True)
        print("✅ Dependências instaladas")
    except subprocess.CalledProcessError as e:
        print(f"❌ Erro instalando dependências: {e}")
        return False
    return True

def create_database_url():
    """Cria URL de conexão PostgreSQL"""
    load_dotenv()
    
    # Tentar usar DATABASE_URL diretamente
    database_url = os.getenv("DATABASE_URL")
    if database_url and database_url.startswith("postgresql"):
        return database_url
    
    # Construir URL a partir de componentes
    host = os.getenv("DB_HOST", "localhost")
    port = os.getenv("DB_PORT", "5432")
    name = os.getenv("DB_NAME", "tasks_database")
    user = os.getenv("DB_USER", "postgres")
    password = os.getenv("DB_PASSWORD", "postgres")
    
    return f"postgresql://{user}:{password}@{host}:{port}/{name}"

def test_connection(database_url):
    """Testa conexão PostgreSQL"""
    print("🔗 Testando conexão PostgreSQL...")
    try:
        engine = create_engine(
            database_url,
            pool_size=5,
            max_overflow=10,
            pool_pre_ping=True,
            echo=True
        )
        
        with engine.connect() as conn:
            # Teste básico
            result = conn.execute(text("SELECT version()"))
            version = result.scalar()
            print(f"✅ Conexão OK - PostgreSQL: {version}")
            
            # Testar permissões
            conn.execute(text("SELECT 1"))
            print("✅ Permissões OK")
            
            return True
            
    except Exception as e:
        print(f"❌ Erro de conexão: {e}")
        return False

def create_database(database_url):
    """Cria banco de dados se não existir"""
    print("🗄️  Criando banco de dados...")
    try:
        from main import Base, engine
        Base.metadata.create_all(bind=engine)
        print("✅ Tabelas criadas com sucesso")
        
        # Verificar tabelas criadas
        with engine.connect() as conn:
            result = conn.execute(text("""
                SELECT table_name 
                FROM information_schema.tables 
                WHERE table_schema = 'public'
            """))
            tables = [row[0] for row in result]
            print(f"📋 Tabelas criadas: {tables}")
            
        return True
    except Exception as e:
        print(f"❌ Erro criando tabelas: {e}")
        return False

def insert_test_data(database_url):
    """Insere dados de teste"""
    print("📝 Inserindo dados de teste...")
    try:
        engine = create_engine(database_url)
        Session = sessionmaker(bind=engine)
        session = Session()
        
        # Inserir tarefa de teste
        session.execute(text("""
            INSERT INTO tasks (title, description, completed, created_at)
            VALUES ('Teste PostgreSQL', 'Tarefa de teste para verificar PostgreSQL', false, NOW())
            ON CONFLICT DO NOTHING
        """))
        session.commit()
        
        # Verificar dados
        result = session.execute(text("SELECT COUNT(*) FROM tasks"))
        count = result.scalar()
        print(f"✅ Dados inseridos - Total de tarefas: {count}")
        
        session.close()
        return True
    except Exception as e:
        print(f"❌ Erro inserindo dados: {e}")
        return False

def main():
    """Função principal"""
    print("=== Configuração PostgreSQL ===")
    
    # 1. Instalar dependências
    if not install_postgresql_deps():
        return False
    
    # 2. Criar URL de conexão
    database_url = create_database_url()
    print(f"🔗 URL de conexão: {database_url.replace(database_url.split('@')[0].split('//')[1], '***')}")
    
    # 3. Testar conexão
    if not test_connection(database_url):
        print("❌ Falha na conexão. Verifique:")
        print("   - PostgreSQL está rodando?")
        print("   - Credenciais estão corretas?")
        print("   - Firewall/Security Groups permitem conexão?")
        return False
    
    # 4. Criar banco
    if not create_database(database_url):
        return False
    
    # 5. Inserir dados de teste
    if not insert_test_data(database_url):
        return False
    
    print("🎉 PostgreSQL configurado com sucesso!")
    print("Para usar PostgreSQL:")
    print("1. Atualize DATABASE_URL no .env")
    print("2. Reinicie a aplicação")
    
    return True

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
