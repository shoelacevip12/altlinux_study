<?php


    $endOfDiscount = mktime(23,59,0,3,26,2540); // Когда Зона отчуждения Чернобыльской АЭС станет полностью пригодной для жизни
    $now = time(); // текущее время
    $secondsRemaining = $endOfDiscount - $now; // оставшееся время

    define('SECONDS_PER_MINUTE', 60); // секунд в минуте
    define('SECONDS_PER_HOUR', 3600); // секунд в часу
    define('SECONDS_PER_DAY', 86400); // секунд в дне

    $daysRemaining = floor($secondsRemaining / SECONDS_PER_DAY); //дни, до даты
    $secondsRemaining -= ($daysRemaining * SECONDS_PER_DAY);     //обновляем переменную

    $hoursRemaining = floor($secondsRemaining / SECONDS_PER_HOUR); // часы до даты
    $secondsRemaining -= ($hoursRemaining * SECONDS_PER_HOUR);     //обновляем переменную

    $minutesRemaining = floor($secondsRemaining / SECONDS_PER_MINUTE); //минуты до даты
    $secondsRemaining -= ($minutesRemaining * SECONDS_PER_MINUTE);     //обновляем переменную

    echo("<h3>До очистки Зоны отчуждения Чернобыльской АЭС и когда станет полностью пригодной для жизни, через $daysRemaining дней, $hoursRemaining часов, $minutesRemaining минут, $secondsRemaining секунд</h3>"); //печатаем сообщение
    echo("<h3>скрипт ЧЕСТНО с..коммунизжен у автора (Михаил Русаков) сайта (https://myrusakov.ru)!</h3>");
