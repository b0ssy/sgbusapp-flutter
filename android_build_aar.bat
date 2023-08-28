set BUILD_DIR=.sgbusapp-flutter\build
set OUTPUT=%BUILD_DIR%\sgbusapp-flutter.aab

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

del "%OUTPUT%"
call flutter --no-color build appbundle --dart-define=API_KEY=cbC/BQ0oRBqXcVzT62uR/A==
echo F | xcopy /s /y build\app\outputs\bundle\release\app-release.aab "%OUTPUT%"
