# Checklist trước khi mở PR

- [ ] `flutter analyze` sạch, `flutter test` qua.
- [ ] Màn vẽ đủ Loading / Empty / Error + Thử lại / Data.
- [ ] Không màu / cỡ chữ / spacing cứng; chỉ dùng widget trong `lib/widgets/`.
- [ ] Đúng ở 360 và 412 dp, `textScaler` 1.3 không tràn.
- [ ] Có test ViewModel với service Fake (cả nhánh Empty / Error).
- [ ] Event analytics đã gắn theo `docs/analytics-plan.md`.
- [ ] Cập nhật trạng thái màn trong `docs/design-traceability.md`.
- [ ] Đối chiếu mục "Xong khi" của feature trong file chia task.
- [ ] Không có secret, API key hay tài khoản test trong diff.
