"""Fixture tạo client ARTEMIS. Chủ file: Hương.

Biến môi trường (KHÔNG commit): ANDROID_SERIAL, ARTEMIS_PROFILE (flash/pro), API key của model.
TODO: hoàn thiện theo README của google/artemis (tên lớp trong đề: ArtemisClient).
"""
import os

import pytest


@pytest.fixture
async def artemis():
    serial = os.environ.get("ANDROID_SERIAL")
    profile = os.environ.get("ARTEMIS_PROFILE", "flash")
    if not serial:
        pytest.skip("Chưa đặt ANDROID_SERIAL")
    # from artemis import ArtemisClient
    # client = ArtemisClient(device_serial=serial, profile=profile)
    # yield client
    # await client.close()
    pytest.skip(f"Chưa cấu hình ArtemisClient (profile={profile})")
