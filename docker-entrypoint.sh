
#!/bin/sh

echo "=================================================="
echo "GRAHAMGO ENTRYPOINT DIAGNOSTICS"
echo "=================================================="

# Ensure Apache uses the prefork MPM required by mod_php.
grep -rl "LoadModule mpm_event_module\|LoadModule mpm_worker_module" /etc/apache2/ 2>/dev/null |
while IFS= read -r f; do
    sed -i '/LoadModule mpm_event_module/d; /LoadModule mpm_worker_module/d' "$f"
    echo "Removed conflicting MPM LoadModule lines from: $f"
done

rm -f /etc/apache2/mods-enabled/mpm_event.load \
      /etc/apache2/mods-enabled/mpm_event.conf \
      /etc/apache2/mods-enabled/mpm_worker.load \
      /etc/apache2/mods-enabled/mpm_worker.conf

ln -sf /etc/apache2/mods-available/mpm_prefork.load \
       /etc/apache2/mods-enabled/mpm_prefork.load

ln -sf /etc/apache2/mods-available/mpm_prefork.conf \
       /etc/apache2/mods-enabled/mpm_prefork.conf

# Configure Apache to use Railway's assigned port.
if [ -n "$PORT" ]; then
    sed -i "s/Listen 80/Listen ${PORT}/" /etc/apache2/ports.conf
    sed -i "s/:80>/:${PORT}>/" /etc/apache2/sites-available/000-default.conf
fi

echo "--- Database environment variable status (values hidden) ---"

for name in MYSQLHOST MYSQLDATABASE MYSQLUSER MYSQLPASSWORD MYSQLPORT; do
    if [ -n "$(printenv "$name")" ]; then
        echo "$name: SET"
    else
        echo "$name: MISSING"
    fi
done

echo "--- PHP VERSION ---"
php -v

echo "--- CODEIGNITER MIGRATION ERROR DETAILS ---"

php -d display_errors=1 -d log_errors=1 spark migrate --all 2>&1
MIGRATION_STATUS=$?

echo "--- MIGRATION EXIT CODE: $MIGRATION_STATUS ---"

if [ "$MIGRATION_STATUS" -ne 0 ]; then
    echo "ERROR: Migration failed."
    echo "Review the PHP or CodeIgniter error messages above."
else
    echo "Migration completed successfully."
fi

echo "=================================================="
echo "Starting Apache"
echo "=================================================="

exec "$@"
