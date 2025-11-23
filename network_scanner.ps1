function Invoke-PerfectNetworkScan {
    # Базовый адрес сети для сканирования (можно изменить под свою сеть)
    $network = "192.168.1."
    
    # Массив для хранения фоновых заданий
    $jobs = @()
    
    # Создаем диапазон IP-адресов от 1 до 254 (типичные адреса хостов в /24 сети)
    1..254 | ForEach-Object {
        # Формируем полный IP-адрес
        $ip = "${network}$_"
        
        # Запускаем фоновое задание для проверки доступности хоста
        $jobs += Start-Job -ScriptBlock {
            param($ip)
            
            # Проверяем доступность хоста с помощью ping
            if (Test-Connection $ip -Count 1 -Quiet -ErrorAction SilentlyContinue) {
                return $ip  #  Возвращаем IP если хост активен
            } else {
                return $null  #  Возвращаем null если хост неактивен
            }
        } -ArgumentList $ip  # Передаем IP-адрес в фоновое задание
    }
    
    Write-Host "⏳ Ожидаем завершения сканирования сети..." -ForegroundColor Yellow
    
    # Ожидаем завершения всех фоновых заданий и получаем результаты
    $results = $jobs | Wait-Job | Receive-Job
    
    # Очищаем фоновые задания из памяти
    $jobs | Remove-Job
    
    # Фильтруем результаты: оставляем только непустые значения (активные хосты)
    $activeHosts = $results | Where-Object { $_ -ne $null }
    
    # Выводим статистику сканирования
    Write-Host " Сканирование завершено!" -ForegroundColor Green
    Write-Host " Найдено активных хостов: $($activeHosts.Count)" -ForegroundColor Cyan
    
    # Возвращаем массив активных IP-адресов
    return $activeHosts
}
