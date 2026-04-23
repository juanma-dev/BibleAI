# Script para iniciar simultáneamente el Backend y el Frontend

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Iniciando La Santa Biblia Asistida por AI" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

# 1. Iniciar el Backend en una nueva ventana de PowerShell
Write-Host "-> Iniciando el Backend (.NET) en una nueva ventana..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit -Command `"cd BibleAiBackend; dotnet run`""

# Pequeña pausa para asegurar que el backend reserve el puerto
Start-Sleep -Seconds 3

# 2. Iniciar el Frontend
Write-Host "-> Iniciando la App Flutter..." -ForegroundColor Yellow
cd santa_biblia
flutter run -d windows
