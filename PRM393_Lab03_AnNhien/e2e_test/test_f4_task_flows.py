"""ARTEMIS Flow 2 / Flow 7 – chỉ chạy khi conftest đã cấu hình thiết bị thật."""
import pytest


@pytest.mark.asyncio
async def test_flow_2_add_task_validation_then_save(artemis):
    result = await artemis.run(
        "Mở Hôm nay, chọn Thêm việc. Chọn Đi bộ nhẹ nhàng, Tiếp tục. "
        "Bấm Lưu việc này khi chưa có tên và xác minh lỗi 'Bác chưa nhập tên việc'. "
        "Chạm 'Đi bộ buổi sáng', đặt giờ 8:00 sáng, lưu và xác minh 'Đã lưu xong!'."
    )
    assert result.succeeded, result.error


@pytest.mark.asyncio
async def test_flow_7_edit_delete_recurring_task(artemis):
    result = await artemis.run(
        "Mở một việc lặp Đi bộ trong Hôm nay để sửa. Đổi giờ, lưu và chọn "
        "'Lần này và các lần sau'. Sau đó xóa việc, chọn 'Chỉ lần này', "
        "xác nhận 'Xóa khỏi lịch', rồi xác minh snackbar có nút 'Hoàn tác'."
    )
    assert result.succeeded, result.error
