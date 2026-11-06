# SolarO

## Conectar el backend

En Android, la app usa `http://10.0.2.2:5000` al ejecutar en modo debug con un
emulador; esa dirección apunta al puerto 5000 de la computadora. Inicia el
backend local en ese puerto antes de ejecutar la app. El permiso para HTTP local
está habilitado únicamente en la variante debug.

Las compilaciones Android profile y release usan
`https://solaro-jboy.onrender.com`. El primer acceso puede tardar mientras el
servicio se activa.

Para probar en un teléfono físico, configura la IP local de la computadora:

```powershell
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5000
```

Reemplaza `192.168.1.10` por la IP de tu computadora y permite el puerto 5000 en
el firewall. También se puede reemplazar la URL predeterminada en cualquier
plataforma mediante `--dart-define=API_BASE_URL=<url>`.
