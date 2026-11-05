@echo off
set "ANALYZER_MODE="
if "%~1"=="--only-changed" set "ANALYZER_MODE=--only-changed"
call "%~dp0analyze_code_config.bat"
if not exist "%CLI_ANALYZER_PATH%\venv\Scripts\python.exe" (
    echo ERROR: cli-code-analyzer Python environment not found at "%CLI_ANALYZER_PATH%\venv\Scripts\python.exe".
    exit /b 1
)
cd /d "%~dp0.."

"%CLI_ANALYZER_PATH%\venv\Scripts\python.exe" "%CLI_ANALYZER_PATH%\main.py" --language %LANGUAGE% --path "." %ANALYZER_MODE% --fail-on-warnings --verbosity minimal --output "code_analysis_results" --rules "code_analysis_rules.json"
set "ANALYZER_EXIT_CODE=%ERRORLEVEL%"

cd /d "%~dp0"
exit /b %ANALYZER_EXIT_CODE%
