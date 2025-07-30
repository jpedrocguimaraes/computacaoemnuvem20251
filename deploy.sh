#!/bin/bash

# Script de deploy para EC2
echo "=== Iniciando Deploy da Aplicação ==="

# Atualizar sistema
sudo yum update -y

# Instalar Python 3 e pip se não estiver instalado
sudo yum install -y python3 python3-pip

# Instalar Node.js e npm
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Instalar PM2 globalmente para gerenciar processos
sudo npm install -g pm2

# Navegar para o diretório da aplicação
cd /home/ec2-user/app

# Instalar dependências do backend
echo "=== Instalando dependências do backend ==="
cd backend
pip3 install -r requirements.txt

# Configurar arquivo .env se não existir
if [ ! -f .env ]; then
    echo "DATABASE_URL=sqlite:///./tasks.db" > .env
    echo "ENVIRONMENT=production" >> .env
    echo "PORT=8000" >> .env
fi

# Inicializar banco de dados
echo "=== Inicializando banco de dados ==="
python3 -c "
try:
    from main import Base, engine
    Base.metadata.create_all(bind=engine)
    print('✅ Banco de dados inicializado')
except Exception as e:
    print(f'❌ Erro inicializando BD: {e}')
"

# Instalar dependências do frontend
echo "=== Instalando dependências do frontend ==="
cd ../frontend
npm install

# Build do frontend
echo "=== Construindo frontend ==="
npm run build

# Copiar arquivos build para servir estaticamente
sudo mkdir -p /var/www/html
sudo cp -r build/* /var/www/html/

# Instalar e configurar nginx
echo "=== Configurando Nginx ==="
sudo yum install -y nginx

# Configurar nginx
sudo tee /etc/nginx/conf.d/app.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Servir arquivos estáticos do frontend
    location / {
        root /var/www/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy para API backend
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # Proxy direto para desenvolvimento
    location /tasks/ {
        proxy_pass http://localhost:8000/tasks/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    location /docs {
        proxy_pass http://localhost:8000/docs;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Iniciar e habilitar nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Voltar para backend e iniciar aplicação
echo "=== Iniciando aplicação backend ==="
cd /home/ec2-user/app/backend

# Configurar PM2 para iniciar o backend
pm2 start main.py --name "todo-backend" --interpreter python3
pm2 startup
pm2 save

echo "=== Deploy concluído! ==="
echo "Frontend disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "API disponível em: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)/docs"
