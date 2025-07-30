#!/bin/bash

echo "=== Diagnóstico do Servidor AWS ==="

# Verificar se PM2 está rodando
echo "1. Status do PM2:"
pm2 status

echo -e "\n2. Logs do backend:"
pm2 logs todo-backend --lines 20

echo -e "\n3. Verificar se o backend está respondendo:"
curl -v http://localhost:8000/health 2>&1 || echo "Backend não está respondendo"

echo -e "\n4. Verificar se as dependências estão instaladas:"
cd /home/ec2-user/app/backend
pip3 list | grep -E "(fastapi|uvicorn|sqlalchemy)"

echo -e "\n5. Verificar se o arquivo main.py existe:"
ls -la /home/ec2-user/app/backend/main.py

echo -e "\n6. Verificar se a porta 8000 está sendo usada:"
netstat -tulpn | grep :8000

echo -e "\n7. Verificar logs do sistema:"
sudo tail -n 10 /var/log/messages

echo -e "\n=== Como corrigir ==="
echo "Se o PM2 não estiver rodando, execute:"
echo "cd /home/ec2-user/app/backend"
echo "pm2 start main.py --name 'todo-backend' --interpreter python3"
echo "pm2 save"
