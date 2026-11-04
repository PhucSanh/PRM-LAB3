"""TC-01, TC-02, TC-13 – Hương. Mẫu: hỏi agent trả về giá trị nhìn thấy, rồi so sánh."""


async def test_tc01_google_sign_in_shows_today(artemis):
    result = await artemis.run(
        "Open the An Nhien app, signed out. Tap 'Tiếp tục với Google', pick the test account. "
        "Verify the 'Hôm nay' screen and 4 bottom tabs are shown. "
        "Report the exact text of the progress line that starts with 'Đã xong'."
    )
    assert result.succeeded, result.error
    # TODO: assert trên giá trị agent báo lại, vd. regex r"Đã xong \d+/\d+ việc"
