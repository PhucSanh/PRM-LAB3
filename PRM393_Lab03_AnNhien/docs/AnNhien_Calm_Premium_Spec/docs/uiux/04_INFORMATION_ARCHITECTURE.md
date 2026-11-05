# 04 — Information architecture & navigation contract

## Domain taxonomy — định nghĩa tránh trùng lặp
| Khái niệm | Là gì | Không phải |
|---|---|---|
| **Lịch** | Danh sách instance hoạt động **đã được lên kế hoạch** theo ngày/giờ; đổi ngày; xem, hoàn thành, dời/bỏ qua theo nghiệp vụ | Thư viện khám phá hoạt động |
| **Hoạt động** | Catalog các hoạt động được phép khám phá, lưu lại, xây dựng thành thói quen | Dòng thời gian công việc đã đặt lịch |
| **Khám phá** | Browse/search/filter gợi ý nội dung phù hợp theo khả năng dữ liệu hiện tại | Lời mời cá nhân từ caregiver |
| **Đã lưu** | Hoạt động bookmark để xem hoặc lên lịch sau | Việc đã hoàn thành |
| **Thói quen** | Hoạt động lặp lại hoặc phân loại nội dung thói quen (repo hiện có 9 nhóm) | Tất cả task trong ngày |
| **Gợi ý** | Caregiver tạo và gửi đề xuất cho elderly; có trạng thái nhận/phản hồi | Hoạt động được tự động đưa vào lịch không xác nhận |
| **Gia đình** | Thành viên được liên kết, ghép đôi, thông tin liên hệ và hỗ trợ | Mọi người dùng trên platform |

### Chốt về “Thói quen”
**Gộp cấu trúc UI vào `Hoạt động`**; **không** đổi domain entity `Habit` thành `Activity` trong backend nếu không có yêu cầu nghiệp vụ. Nếu hiện tại chỉ hỗ trợ xem 9 nhóm thói quen mà chưa có thư viện `saved/explore`, để lại empty state rõ ràng và không ghi dữ liệu giả vào backend.

## Navigation người cao tuổi (3 top-level destinations)
```
Elderly Shell
├── Lịch [default root sau onboarding; thay /week về mặt UX]
│   ├── Chọn ngày/tuần
│   ├── Chi tiết hoạt động đã đặt lịch
│   ├── Hoàn thành / dời / bỏ qua (nếu backend hỗ trợ)
│   ├── Tạo hoạt động (nếu đã có implementation)
│   └── Nhắc nhở (detail route)
├── Hoạt động
│   ├── Khám phá
│   │   └── Chi tiết hoạt động → Lưu / Đặt lịch (nếu có)
│   ├── Đã lưu
│   │   └── Chi tiết hoạt động → Xóa lưu / Đặt lịch (nếu có)
│   └── Thói quen
│       └── Danh mục 9 thói quen → Chi tiết nhóm
└── Gia đình
    ├── Thành viên / trạng thái ghép đôi
    ├── Thêm / chỉnh sửa / liên hệ (theo chức năng thật)
    └── Lời gợi ý từ người thân → Xem / phản hồi
Global destinations: Inbox, Settings, Profile, Help, Data, Account, Voice (contextual)
```

## Navigation người thân (3 top-level destinations)
```
Caregiver Shell
├── Lịch
│   ├── Day / Week / Month
│   ├── Tạo hoạt động → Lặp lại → Kiểm tra → Đã gửi
│   └── Chi tiết / Chỉnh sửa nếu được phép
├── Gợi ý
│   ├── Soạn gợi ý
│   ├── Lịch sử/trạng thái nếu repository có dữ liệu
│   └── Chi tiết (nếu có)
└── Gia đình
    ├── Thành viên liên kết
    ├── Kết nối / Nhập mã
    └── Thông tin quyền truy cập
Global: Inbox, Settings, Profile, Account, Help
```

## Vai trò, permissions, linking
- Authenticated role quyết định shell; mọi màn phải kiểm tra quyền theo **backend/session** chứ không dựa trên `path.startsWith` duy nhất.
- Nếu chưa login → Sign-in. Chưa chọn role → Role. Elder chưa hoàn tất setup → onboarding. Caregiver chưa paired → Pairing. Hiện `AUTH_GUARD=false` cho demo; thiết kế route không được giả định guard luôn bật.
- Mở thông báo phải resolve đúng target và quyền; nếu target không hợp lệ/không thuộc gia đình/đã xóa → friendly unavailable state + cách về tab gốc, không crash/loại bỏ thông báo trong âm thầm.
- Sign-out hoặc switch role reset protected navigation stacks và cache liên quan theo existing Riverpod/session contracts.

## Global nav & header
- Bottom nav chỉ 3 đích, **icon + nhãn luôn hiển thị**, active state kết hợp fill + indicator + color, no icon-only.
- AppBar: Page title; tối đa 1–2 trailing contextual actions (ví dụ Inbox, Settings). Không nhét thêm cả profile/bell/search/help vào cùng một hàng.
- Back xuất hiện ở màn chi tiết/form; top-level root không giả Back. Dialog không phải thay thế navigation.
- Search dùng trong Hoạt động nếu catalog thực sự hỗ trợ; không đặt search giả.

## Navigation behavior — acceptance contract
| Trigger | Result | Preserve |
|---|---|---|
| Chọn tab khác | Switch đúng branch | Scroll/filter của branch cũ |
| Chạm tab đã chọn khi đang ở child route | Pop về root của branch đó | Các branch khác |
| Chạm tab đã chọn khi ở root | Không tạo duplicate route | Root state, không tự refresh data mạnh |
| Mở chi tiết | Push child vào đúng context/branch | Scroll và selected date |
| Back | Pop child; ở root defer cho platform/back handler | Form warning nếu dirty |
| Deep link notification | Resolve role, auth, entity và route phù hợp | Có thể back đến shell hợp lệ |
| Save form success | pop(result) hoặc route result theo workflow đang có | Một lần submit, không tạo duplicate |
| Cancel dirty form | Confirm Save/Discard/Stay (nếu áp dụng) | Dữ liệu đã nhập nếu chọn Stay |
| Session changed | Clear old role data/stacks | Không lộ dữ liệu người dùng cũ |
| Landscape/tablet | Bottom nav → rail thích ứng | Same hierarchy |

### Back trên root tab
Không buộc Back chuyển sang tab trước đó. Theo default platform Android, root app có thể exit/background; nếu UX kiểm thử thấy phù hợp có thể đề xuất riêng. Không hiển thị confirm exit trên mọi Back.

## Deep-link & legacy route compatibility
**Không xóa `/today` trong bước đầu.** Đây là route legacy dùng làm initial path hiện tại và có thể là target thông báo. Sau khi triển khai shell mới, chuyển default/redirect có kiểm soát sang `/calendar` hoặc giữ `/week` path nội bộ, **chỉ sau khi đã audit toàn bộ references**.

| Legacy | Proposed canonical UX destination | Migration note |
|---|---|---|
| `/today` | `/calendar` (không sửa nội dung `/today`) | Legacy redirect/alias khi an toàn; giữ nếu external link cần |
| `/week` | `/calendar` | Giữ alias, preserve `:date` |
| `/habits` | `/activities?section=habits` | Preserve `/habits/:key` → detail |
| `/family` | `/family` | Giữ URL nếu được |
| `/today/task/:id` | `/calendar/task/:id` | Audit notification references |
| `/today/add` + subpaths | `/calendar/add` hoặc canonical `activity` form | Giữ workflow nếu chưa implement |
| `/today/voice` | contextual voice entry | Không làm mất khả năng gọi |
| `/today/suggestions/:id` | `/suggestions/:id` (view elderly) | Preserve `from` query |
| `/caregiver/schedule` | caregiver schedule root | Có thể giữ exact path |
| `/caregiver/suggest` | caregiver suggest root | Có thể giữ exact path |
| `/inbox/suggestions/:id` | inbox detail | Giữ tương thích |

**Đây là mapping đề xuất, không phải command rename hàng loạt.** Routing implementation phải re-check `notificationTarget`, `initialRouteProvider`, `go/push/pop` tại mỗi callsite, `StatefulShellRoute.indexedStack` và query handling. Không tạo redirect cycle. Test notification cold-start/warm-start.

## Định nghĩa done IA
- Mỗi màn chỉ có một parent rõ; path usable khi mở trực tiếp nếu được phép; không có “dead end” không hướng dẫn.
- Không làm thay đổi uid/pairing authorization và notification route semantics.
- Explore/Saved/Habits là nội dung cấp 2, **không** biến thành 3 bottom tabs.
- Caregiver **không** hiển thị elder `AppShell` 3-tab ngoài ý muốn.

## Typography dependency — TYPE-01
Mọi chữ UI trên các màn/component thuộc tài liệu này phải dùng semantic tokens tại `02_VISUAL_TOKENS.md` → TYPE-01 (v1.1.0), gồm cả nhãn navigation, form, hint/error, dialog, loading/empty/placeholder và metadata. Không định nghĩa lại cỡ chữ/weight tại đây hoặc giảm chữ vì density. Shared chưa xác định vai trò dùng bộ elderly; layout phải wrap/scroll và tự tăng chiều cao theo chữ.
