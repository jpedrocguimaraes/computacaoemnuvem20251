#!/bin/bash

# Script para testar a aplicação localmente
echo "=== Testando Aplicação Localmente ==="

# Verificar se Python está instalado
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 não encontrado. Instale Python 3.9+ primeiro."
    exit 1
fi

# Verificar se Node.js está instalado
if ! command -v node &> /dev/null; then
    echo "❌ Node.js não encontrado. Instale Node.js 18+ primeiro."
    exit 1
fi

echo "✅ Python e Node.js encontrados"

# Testar backend
echo "=== Testando Backend ==="
cd backend

# Criar ambiente virtual se não existir
if [ ! -d "venv" ]; then
    echo "Criando ambiente virtual..."
    python3 -m venv venv
fi

# Ativar ambiente virtual
source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null

# Instalar dependências
echo "Instalando dependências do backend..."
pip install -r requirements.txt

# Testar importações
echo "Testando importações..."
python -c "from main import app; print('✅ Backend imports OK')" || {
    echo "❌ Erro nas importações do backend"
    exit 1
}

# Iniciar backend em background para teste
echo "Iniciando backend para teste..."
python main.py &
BACKEND_PID=$!

# Aguardar o backend inicializar
sleep 5

# Testar endpoint de health
echo "Testando endpoint de health..."
curl -f http://localhost:8000/health > /dev/null 2>&1 && echo "✅ Backend health check OK" || {
    echo "❌ Backend health check falhou"
    kill $BACKEND_PID 2>/dev/null
    exit 1
}

# Parar backend
kill $BACKEND_PID 2>/dev/null

cd ..

# Testar frontend
echo "=== Testando Frontend ==="
cd frontend

# Instalar dependências
echo "Instalando dependências do frontend..."
npm install

# Testar build
echo "Testando build do frontend..."
npm run build && echo "✅ Frontend build OK" || {
    echo "❌ Frontend build falhou"
    exit 1
}

cd ..

echo "🎉 Todos os testes passaram! A aplicação está pronta para deploy."
