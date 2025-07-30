#!/bin/bash

echo "=== Corrigindo Backend no AWS ==="

# Parar processos antigos
pm2 stop all
pm2 delete all

# Navegar para backend
cd /home/ec2-user/app/backend

# Reinstalar dependências
echo "Instalando dependências..."
pip3 install -r requirements.txt

# Recriar banco de dados
echo "Criando banco de dados..."
python3 -c "from main import Base, engine; Base.metadata.create_all(bind=engine)" 2>/dev/null || echo "Erro ao criar DB"

# Testar importação
echo "Testando importação..."
python3 -c "from main import app; print('Backend importado com sucesso!')"

# Iniciar backend com PM2
echo "Iniciando backend..."
pm2 start main.py --name "todo-backend" --interpreter python3

# Aguardar inicialização
sleep 5

# Verificar status
pm2 status
curl -f http://localhost:8000/health && echo "✅ Backend funcionando!" || echo "❌ Backend com problemas"

echo "=== Correção concluída ==="
