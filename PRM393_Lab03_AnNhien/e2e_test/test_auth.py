"""TC-01, TC-02, TC-13: assert observed UI, not only agent completion."""
import json


TABS = ["Trang chủ", "Khám phá", "Thói quen", "Gia đình", "Cá nhân"]


def observed(result):
    assert result.succeeded, result.error
    output = result.output
    if isinstance(output, str):
        output = json.loads(output)
    assert isinstance(output, dict), "ARTEMIS must return the requested JSON evidence"
    return output


async def test_tc01_google_sign_in_shows_home(artemis):
    result = await artemis.run(
        "Open An Nhien, signed out. Tap 'Tiếp tục với Google' and select the "
        "existing test account with elder role and completed onboarding. "
        "Verify the home screen, greeting and all five bottom tabs. "
        "Read their exact labels from the screen; do not infer missing elements.",
        expected_output='JSON object: {"greeting": exact greeting text, "tabs": array of the five visible tab labels in order}',
    )
    ui = observed(result)
    assert ui.get("greeting") == "Chào ngày mới,"
    assert ui.get("tabs") == TABS


async def test_tc02_cancel_google_sign_in(artemis):
    result = await artemis.run(
        "Start An Nhien signed out. Tap 'Tiếp tục với Google', then cancel the "
        "Google account picker. Verify you remain on sign-in and read the "
        "cancellation message. Do not choose or create an account.",
        expected_output='JSON object: {"sign_in_button": exact Google sign-in button label, "message": exact cancellation message}',
    )
    ui = observed(result)
    assert ui.get("sign_in_button") == "Tiếp tục với Google"
    assert "chưa đăng nhập" in ui.get("message", "").lower()


async def test_tc13_sign_out_returns_to_sign_in(artemis):
    result = await artemis.run(
        "Start An Nhien signed in with the test account. Open Cá nhân, choose "
        "Đăng xuất and confirm. Verify Google sign-in is shown and the former "
        "user's name and schedule are no longer visible.",
        expected_output='JSON object: {"sign_in_button": exact Google sign-in label, "old_user_data_visible": boolean}',
    )
    ui = observed(result)
    assert ui.get("sign_in_button") == "Tiếp tục với Google"
    assert ui.get("old_user_data_visible") is False
