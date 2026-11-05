"""ARTEMIS Flow 3 – chỉ chạy khi conftest đã cấu hình Android thật."""
import pytest


@pytest.mark.asyncio
async def test_flow_3_complete_and_undo(artemis):
    result = await artemis.run(
        "Mở Hôm nay. Chọn việc tiếp theo, bấm Đã xong, xác nhận 'Đúng, đã xong'. "
        "Xác minh việc có trạng thái Đã xong và snackbar có nút Hoàn tác. "
        "Bấm Hoàn tác và xác minh việc trở về Chưa làm."
    )
    assert result.succeeded, result.error


@pytest.mark.asyncio
async def test_flow_3_postpone_and_skip(artemis):
    result = await artemis.run(
        "Mở Hôm nay. Với việc tiếp theo, bấm Dời lại, chọn Sau 30 phút và xác minh "
        "giờ mới tăng 30 phút. Sau đó mở một việc chưa làm khác, chọn Hôm nay bỏ qua, "
        "xác nhận Bỏ qua hôm nay và xác minh trạng thái Bỏ qua."
    )
    assert result.succeeded, result.error


@pytest.mark.asyncio
async def test_flow_3_detail_and_empty_state(artemis):
    result = await artemis.run(
        "Mở chi tiết một việc trong Hôm nay và xác minh tên việc, Giờ làm, Lặp lại, "
        "Lời nhắc, các nút Đã xong, Dời lại và Hôm nay bỏ qua. Nếu lịch hôm nay rỗng, "
        "xác minh màn 'Hôm nay chưa có việc' có nút Thêm việc đầu tiên."
    )
    assert result.succeeded, result.error
