# DevConnect Deliverables

Thư mục này chứa file nộp chính cho bài giữa kỳ và script để sinh lại report PDF/presentation PPTX khi cần.

## Chạy lại generator

```bash
npm install
npm run pdf
npm run pptx
npm run all
```

## Cấu trúc hiện tại

```text
deliverables/
├── assets/                                      # Ảnh minh họa và screenshot app
├── DevConnect_Midterm_Report_PRM393.pdf         # Report PDF cuối cùng
├── DevConnect_Midterm_Presentation_PRM393.pptx  # Slide PPTX cuối cùng
├── generate-pdf.js                              # Script sinh PDF bằng Puppeteer
├── generate-pptx.js                             # Script sinh PPTX bằng pptxgenjs
├── package.json
├── package-lock.json
└── README.md
```

## Ghi chú cleanup

- `node_modules/` không được giữ trong repo; nếu cần sinh lại PDF/PPTX thì chạy `npm install`.
- Các thư mục nháp `report-pdf/` và `presentation-pptx/` đã được xóa để tránh trùng với file cuối cùng.
- PDF/PPTX hiện tại đi theo scope `midterm-mobile`, không dùng để áp đặt cấu trúc cho bộ `docs/`.
- Screenshot mobile thật sẽ lắp sau khi app chạy ổn định; generator hiện đang để placeholder `Chèn screenshot mobile sau` cho các phần demo.
- Nếu muốn generator tự ưu tiên ảnh thật, đặt file vào `deliverables/assets/mobile-screenshots/` theo tên `<ten_anh>_actual.png`, ví dụ `04_home_feed_actual.png`.
