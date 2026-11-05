"""Fixture ARTEMIS dùng cho E2E trên Android thật.

Không commit URL nội bộ, token, API key hay kết quả giả. Xem README.md trong
thư mục này để cấu hình ARTEMIS_BASE_URL, ARTEMIS_TOKEN và ANDROID_SERIAL.
"""
import os

import pytest
from artemis_client import ArtemisClient


@pytest.fixture
async def artemis():
    base_url = os.environ.get("ARTEMIS_BASE_URL")
    serial = os.environ.get("ANDROID_SERIAL")
    profile = os.environ.get("ARTEMIS_PROFILE", "flash")
    token = os.environ.get("ARTEMIS_TOKEN")
    if not base_url:
        pytest.skip("Chưa đặt ARTEMIS_BASE_URL (URL daemon ARTEMIS nội bộ)")
    if not serial:
        pytest.skip("Chưa đặt ANDROID_SERIAL")

    client = ArtemisClient(base_url, token=token)
    try:
        # Preflight nhanh: lỗi daemon/device được báo trước khi agent chạy test.
        await client.health()
    except Exception as error:  # pragma: no cover - phụ thuộc daemon ngoài
        pytest.skip(f"Không kết nối được ARTEMIS tại {base_url}: {error}")

    class ArtemisSession:
        async def run(self, instruction: str):
            return await client.run(
                instruction,
                profile=profile,
                device_serial=serial,
            )

    yield ArtemisSession()
