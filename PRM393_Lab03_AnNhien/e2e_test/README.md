# Chạy ARTEMIS E2E

ARTEMIS chạy trên Android device/emulator thật, không chạy trên Chrome fake.
SDK được ghim trong `pyproject.toml`; không commit URL daemon, token, API key
hoặc ảnh/kết quả thuộc tài khoản thật.

## Cài môi trường

```powershell
cd e2e_test
uv sync
```

## Biến môi trường phiên chạy

```powershell
$env:ARTEMIS_BASE_URL = 'http://127.0.0.1:8000'
$env:ARTEMIS_TOKEN = '...'; # chỉ khi daemon yêu cầu token
$env:ANDROID_SERIAL = 'emulator-5554'
$env:ARTEMIS_PROFILE = 'flash'
```

`ARTEMIS_BASE_URL` là URL daemon của nhóm; không suy đoán hoặc public endpoint.
Kiểm tra device trước khi chạy:

```powershell
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" devices -l
uv run pytest -q test_f4_task_flows.py
```

## Chạy ba lần và lưu bằng chứng

Từ `e2e_test/`:

```powershell
uv run python run_artemis.py --runs 3 test_f4_task_flows.py
```

Runner tạo JUnit XML và `summary.json` vào `evidence/artemis/<UTC timestamp>/`.
Chỉ sau khi cả ba lượt chạy thật, chép pass rate vào `docs/test-plan.md`.
