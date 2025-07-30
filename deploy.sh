#!/bin/bash

echo "=== Iniciando Deploy da Aplicação ==="

# Atualizar pacotes essenciais
sudo yum update -y

# Instalar Python 3 e pip se necessário
sudo yum install -y python3 python3-pip

# Instalar Node.js e npm (v18)
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
sudo yum install -y nodejs

# Instalar PM2
sudo npm install -g pm2

# Caminho da aplicação
cd /home/ec2-user/app

# Backend: instalar dependências e preparar banco
echo "=== Instalando dependências do backend ==="
cd backend
pip3 install -r requirements.txt

echo "=== Inicializando banco de dados ==="
python3 -c "from main import Base, engine; Base.metadata.create_all(bind=engine)"

# Frontend: instalar dependências e build
echo "=== Instalando dependências do frontend ==="
cd ../frontend
npm install

echo "=== Construindo frontend ==="
npm run build

# Copiar arquivos do frontend para diretório público
echo "=== Atualizando arquivos públicos do frontend ==="
sudo mkdir -p /var/www/html
sudo cp -r build/* /var/www/html/

# Instalar Nginx
echo "=== Configurando Nginx ==="
sudo yum install -y nginx

# Criar configuração do Nginx (evitando proxies redundantes)
sudo tee /etc/nginx/conf.d/app.conf > /dev/null <<EOF
server {
    listen 80;
    server_name _;

    # Servir frontend (React build)
    location / {
        root /var/www/html;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    # Proxy para FastAPI
    location /api/ {
        proxy_pass http://localhost:8000/;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOF

# Reiniciar Nginx
sudo systemctl restart nginx
sudo systemctl enable nginx

# Voltar ao backend e iniciar com PM2
echo "=== Iniciando aplicação backend com PM2 ==="
cd /home/ec2-user/app/backend

# Verifica se o app já está rodando e reinicia ou inicia do zero
if pm2 describe todo-backend > /dev/null; then
    pm2 restart todo-backend
else
    pm2 start main.py --name "todo-backend" --interpreter python3
fi

# Garantir que PM2 inicie no boot
pm2 startup | tail -n 1 | bash
pm2 save

# Mostrar URLs de acesso
PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
echo "=== Deploy concluído! ==="
echo "✅ Frontend: http://$PUBLIC_IP/"
echo "✅ Backend (FastAPI docs): http://$PUBLIC_IP/api/docs"