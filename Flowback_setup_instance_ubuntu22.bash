#!/usr/bin/bash
#This is an automatic setup code

# Create directory
echo what is the name of the new instance? BEWARE old instances and their databases
read iname
mkdir "$iname"
cd "$iname"
echo what instance to copy from?
read cname
cp -R ../"$cname"/manage/ .
chmod u+x manage/setup_backend.bash
chmod u+x manage/setup_frontend.bash
./manage/setup_backend.bash
./manage/setup_frontend.bash

cd backend
rm -r .env
touch .env
echo what is the new django secret key?
read DJANGO_SECRET_KEY
echo "DJANGO_SECRET=${DJANGO_SECRET_KEY}" >> .env
echo "DEBUG=False" >> .env
echo "PG_SERVICE=flowback_${iname}" >> .env
echo "EMAIL_HOST=\"mail.privateemail.com\"" >> .env
echo "EMAIL_PORT=587" >> .env
echo "EMAIL_HOST_USER=\"noreply@flowback.org\"" >> .env
echo "EMAIL_HOST_PASSWORD=\"6iz7YGzSbHiXRU\"" >> .env
rm -r .flowback_pgpass
touch .flowback_pgpass
chmod 600 .flowback_pgpass
echo "localhost:5432:${iname}.flowback.org:gofven:Gomwk815" >> .flowback_pgpass

dropdb "$iname".flowback.org
createdb "$iname".flowback.org
echo "[flowback_${iname}]" >> /etc/postgresql-common/pg_service.conf
echo "host=localhost" >> /etc/postgresql-common/pg_service.conf
echo "user=gofven" >> /etc/postgresql-common/pg_service.conf
echo "dbname=${iname}.flowback.org" >> /etc/postgresql-common/pg_service.conf
echo "port=5432" >> /etc/postgresql-common/pg_service.conf

source venv/bin/activate
python manage.py migrate
deactivate

cd ../frontend
echo what is the backend port at frontend?
read BACKEND_PORT
echo what is the frontend port at frontend?
read FRONTEND_PORT

echo "${iname}.flowback.org {" >> /etc/caddy/Caddyfile
echo "reverse_proxy * :${FRONTEND_PORT}" >> /etc/caddy/Caddyfile
echo "reverse_proxy /admin* :${FRONTEND_PORT}" >> /etc/caddy/Caddyfile
echo "reverse_proxy /static/admin* :${FRONTEND_PORT}" >> /etc/caddy/Caddyfile
echo "}" >> /etc/caddy/Caddyfile
echo "api.${iname}.flowback.org {" >> /etc/caddy/Caddyfile
echo "reverse_proxy * :${BACKEND_PORT}" >> /etc/caddy/Caddyfile
echo "}" >> /etc/caddy/Caddyfile

rm vite.config.js
touch vite.config.js
echo "import { sveltekit } from '@sveltejs/kit/vite';" >> vite.config.js
echo "/** @type {import('vite').UserConfig} \*/" >> vite.config.js
echo "const config = {" >> vite.config.js
echo "  plugins: [sveltekit()]," >> vite.config.js
echo "  optimizeDeps: {" >> vite.config.js
echo "       exclude: ['chart.js']" >> vite.config.js
echo "}," >> vite.config.js
echo "  server: {" >> vite.config.js
echo "       //Insert port here, TODO: Make it easier for backend to add port" >> v>echo "       port: ${FRONTEND_PORT}," >> vite.config.js
echo "       strictPort: true" >> vite.config.js
echo "}};" >> vite.config.js
echo "export default config;" >> vite.config.js
cp ../../"$cname"/frontend/.env .
rm .env
touch .env
echo "VITE_API=https://api.${iname}.flowback.org" >> .env
echo "VITE_WEBSOCKET_API=wss://api.${iname}.flowback.org" >> .env
echo "// DEV or PROD" >> .env
echo "VITE_MODE=PROD" >> .env
echo "// For disabling group creation (need to put an env in the backend aswell)" >>echo "VITE_DISABLE_GROUP_CREATION=false" >> .env

cd ../manage
rm update_backend.sh
touch update_backend.sh
echo "screen -XS flowback-${iname}-backend quit" >> update_backend.sh
echo "cd ../backend" >> update_backend.sh
echo "source venv/bin/activate" >> update_backend.sh
echo "git pull https://github.com/gofven/flowback.git master" >> update_backend.sh
echo "python3.10 -m pip install -r requirements.txt" >> update_backend.sh
echo "python3.10 manage.py migrate" >> update_backend.sh
echo "deactivate" >> update_backend.sh
echo "screen -S flowback-${iname}-backend -dm bash -c \"source venv/bin/activate; p>rm update_frontend.sh
touch update_frontend.sh
echo "screen -XS flowback-${iname}-frontend quit" >> update_frontend.sh
echo "cd ../frontend" >> update_frontend.sh
echo "git pull https://github.com/lokehagberg/flowback-frontend.git" >> update_fron>echo npm install >> update_frontend.sh
echo "screen -S flowback-\"$iname\"-frontend -dm bash -c \"yarn run dev\"" >> updat>echo caddy reload --config /etc/caddy/Caddyfile >> update_frontend.sh
bash update.sh

