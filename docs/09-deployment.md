# 09 - Deployment

## Docker (Rekomendasi Utama)

### Docker Compose Services

| Service   | Image               | Port                 | Fungsi             |
| --------- | ------------------- | -------------------- | ------------------ |
| `app`     | Custom (Dockerfile) | -                    | PHP-FPM 8.4 Alpine |
| `nginx`   | nginx:1.27-alpine   | 8080:80              | Reverse proxy      |
| `db`      | mariadb:11.4        | 3307:3306            | Database           |
| `redis`   | redis:7-alpine      | 6380:6379            | Cache              |
| `mailpit` | axllent/mailpit     | 1025:1025, 8025:8025 | Dev mail catcher   |

### Langkah Deployment Docker

```bash
# 1. Clone project
git clone <repo-url>
cd new-gereja-app

# 2. Copy environment
cp api/.env.example api/.env.docker

# 3. Edit api/.env.docker sesuai kebutuhan
# Penting:
#   DB_HOST=db
#   DB_USERNAME=laravel
#   DB_PASSWORD=laravel
#   REDIS_HOST=redis
#   QUEUE_CONNECTION=database (atau redis)

# 4. Build dan start containers
docker-compose up -d --build

# 5. Install dependencies
docker exec -it gereja_api_app composer install
docker exec -it gereja_api_app npm install

# 6. Generate app key
docker exec -it gereja_api_app php artisan key:generate

# 7. Run migrations
docker exec -it gereja_api_app php artisan migrate

# 8. Build frontend assets
docker exec -it gereja_api_app npm run build

# 9. Storage link
docker exec -it gereja_api_app php artisan storage:link
```

## Queue

```bash
# Development (via composer dev script)
php artisan queue:listen --tries=1 --timeout=0

# Production (Supervisor recommended)
php artisan queue:work database --tries=3 --timeout=90 --sleep=3
```

### Supervisor Config (Production)

```ini
[program:gereja-queue]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/html/artisan queue:work database --tries=3 --timeout=90 --sleep=3
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
numprocs=2
redirect_stderr=true
stdout_logfile=/var/www/html/storage/logs/queue.log
```

## Scheduler

```bash
# Tambahkan ke crontab
* * * * * cd /var/www/html && php artisan schedule:run >> /dev/null 2>&1
```

### Scheduled Tasks:

| Command                       | Schedule         |
| ----------------------------- | ---------------- |
| `ArchiveExpiredEventsCommand` | Every 15 min     |
| `SendEventReminderCommand`    | Every 10 min     |
| `SendEventLastCallCommand`    | Every 10 min     |
| `SendServiceFollowUpCommand`  | Daily 08:00      |
| `SendKkReminderCommand`       | Daily 09:00      |
| `SendAdminDigestCommand`      | Weekly Mon 08:30 |

## Nginx

Docker config tersedia di `docker/nginx/default.conf`. Untuk standalone:

```nginx
server {
    listen 80;
    server_name api.gereja.com;
    root /var/www/html/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass app:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

## Storage & Permission

```bash
# Storage directories
chmod -R 775 storage bootstrap/cache
chown -R www-data:www-data storage bootstrap/cache

# Create storage link
php artisan storage:link

# Storage structure needed:
# storage/app/public/profile-photos/
# storage/app/public/event-documentations/
# storage/app/public/news-attachments/
# storage/app/temp/  (untuk ZIP download)
```

## Migration

```bash
# Run semua migration
php artisan migrate

# Fresh migration (WARNING: drop all tables)
php artisan migrate:fresh

# Rollback
php artisan migrate:rollback
```

## Cache

```bash
# Config cache (production)
php artisan config:cache

# Route cache (production)
php artisan route:cache

# View cache
php artisan view:cache

# Clear all cache
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear
```

## Build Asset (Laravel)

```bash
npm install
npm run build    # Production build
npm run dev      # Development server
```

## Flutter Build

```bash
# Install dependencies
flutter pub get

# Run in development
flutter run

# Build Android APK
flutter build apk

# Build iOS
flutter build ios

# Build Web
flutter build web

# Build untuk semua platform
flutter build apk && flutter build ios && flutter build web
```

## Development (All-in-One)

Script `run.sh` dan `composer dev` menjalankan semua service secara paralel:

```bash
cd api
composer dev
# Menjalankan:
# - php artisan serve (API server)
# - php artisan queue:listen (Queue worker)
# - php artisan pail (Log viewer)
# - npm run dev (Vite dev server)
```
