
#!/bin/bash
set -e

echo "🔧 Bootstrapping Laravel app inside container..."

# === 1. Create Laravel if missing ===
if [ -z "$(find /var/www/html -mindepth 1 -not -path '/var/www/html/.gitkeep' -print -quit)" ]; then
  echo "📦 Installing base Laravel project (fila-starter)..."
  composer create-project --prefer-dist raugadh/fila-starter . --no-interaction
else
  echo "✅ Laravel project already present, skipping setup."
fi

# === 2. Prepare .env file ===
ENV_PATH="/var/www/html/.env"

if [ ! -f "$ENV_PATH" ]; then
  echo "📄 Generating fresh .env file..."
else
  echo "♻️ Replacing existing .env with updated config..."
fi

cat <<EOF > $ENV_PATH
APP_NAME="${PROJECT_NAME}"
APP_ENV=local
APP_KEY=base64:jU6xg8sp9ia37ypFlTVk1CAFx6MmeXRukO1W987uUzI=
APP_DEBUG=true
APP_TIMEZONE=Asia/Jakarta
APP_URL="${DOMAIN}"
ASSET_URL="${DOMAIN}"
DEBUGBAR_ENABLED=false
ASSET_PREFIX=

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

LOG_CHANNEL=stack
LOG_LEVEL=debug

DB_CONNECTION=mariadb
DB_HOST=db
DB_PORT=3306
DB_DATABASE="${PROJECT_NAME}"
DB_USERNAME=root
DB_PASSWORD=p455w0rd

SESSION_DRIVER=database
SESSION_LIFETIME=120
SESSION_ENCRYPT=true

REDIS_CLIENT=phpredis
REDIS_HOST=127.0.0.1
REDIS_PORT=6379

MAIL_MAILER=log
MAIL_HOST=127.0.0.1
MAIL_PORT=2525
MAIL_FROM_ADDRESS="hello@example.com"
MAIL_FROM_NAME="${APP_NAME}"

QUEUE_CONNECTION=database
FILESYSTEM_DISK=local

VITE_APP_NAME="${APP_NAME}"
EOF

# === 3. Wait for DB to be reachable ===
DB_HOST=$(grep DB_HOST $ENV_PATH | cut -d '=' -f2)
DB_PORT=$(grep DB_PORT $ENV_PATH | cut -d '=' -f2)
RETRIES=30

echo "⏳ Waiting for DB ($DB_HOST:$DB_PORT)..."
until nc -z "$DB_HOST" "$DB_PORT"; do
  ((RETRIES--))
  if [ "$RETRIES" -le 0 ]; then
    echo "❌ DB not reachable, exiting."
    exit 1
  fi
  sleep 2
done

echo "✅ DB is ready!"

# === 4. Install dependencies if not present ===
if [ ! -d vendor ]; then
  echo "📦 Running composer install..."
  composer install --no-interaction --optimize-autoloader
fi

# === 5. Generate Laravel app key ===
if [ ! -f storage/oauth-private.key ]; then
  echo "🔑 Generating application key..."
  php artisan key:generate --force
fi

# === 6. Permissions ===
echo "🔐 Setting directory permissions..."
mkdir -p storage bootstrap/cache
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# === 7. Migrate DB ===
echo "📁 Running DB migrations..."
php artisan migrate --force

# === 8. Project init ===
echo "⚙️ Running custom init (project:init)..."
php artisan project:init || true

# === 9. Create storage symlink ===
echo "🔗 Linking storage folder..."
php artisan storage:link || true

# === 10. Start cron service ===
echo "⏱️ Starting cron..."
service cron start

# === 11. Export optional env vars ===
ENV_FILE=".env"
for VAR in XDEBUG PHP_IDE_CONFIG REMOTE_HOST; do
  VALUE=$(grep "^$VAR=" "$ENV_FILE" | cut -d '=' -f2-)
  if [ -n "$VALUE" ]; then
    sed -i "/$VAR/d" ~/.bashrc
    echo "export $VAR=$VALUE" >> ~/.bashrc
  fi
done
. ~/.bashrc

# === 12. Set REMOTE_HOST fallback ===
REMOTE_HOST=${REMOTE_HOST:-host.docker.internal}
echo "export REMOTE_HOST=$REMOTE_HOST" >> ~/.bashrc
. ~/.bashrc

# === 13. Toggle Xdebug if enabled ===
XDEBUG_CONFIG="/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini"
if [ "$XDEBUG" == "true" ] && [ ! -f "$XDEBUG_CONFIG" ]; then
  echo "🪲 Enabling Xdebug..."
  docker-php-ext-enable xdebug
  {
    echo "xdebug.mode=debug"
    echo "xdebug.start_with_request=yes"
    echo "xdebug.client_host=$REMOTE_HOST"
  } >> "$XDEBUG_CONFIG"
elif [ -f "$XDEBUG_CONFIG" ]; then
  echo "🔕 Disabling Xdebug..."
  rm -f "$XDEBUG_CONFIG"
fi

echo "🚀 Laravel is ready to serve."
exec "$@"
