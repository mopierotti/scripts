for %%b in (%*) do for /f "tokens=5" %%a in ('netstat -anop tcp ^| find ":%%b" ^| find "LISTENING"') do taskkill /f /pid %%a