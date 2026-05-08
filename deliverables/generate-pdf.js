const fs = require('fs');
const path = require('path');
const puppeteer = require('puppeteer');

const OUT = path.join(__dirname, 'DevConnect_Midterm_Report_PRM393.pdf');
const ASSETS = path.join(__dirname, 'assets');
const SHOTS = path.join(ASSETS, 'screenshots');
const ACTUAL_SHOTS = path.join(ASSETS, 'mobile-screenshots');
const USE_SCREENSHOTS = true;

function assetPath(name) {
  const base = name.replace(/\.png$/i, '');
  const actual = path.join(ACTUAL_SHOTS, `${base}_actual.png`);
  if (fs.existsSync(actual)) return actual;
  const direct = path.join(ASSETS, name);
  const shot = path.join(SHOTS, name);
  if (fs.existsSync(direct)) return direct;
  if (fs.existsSync(shot)) return shot;
  return null;
}

function imgData(name) {
  const file = assetPath(name);
  if (!file) return '';
  const ext = path.extname(file).replace('.', '') || 'png';
  const data = fs.readFileSync(file).toString('base64');
  return `data:image/${ext};base64,${data}`;
}

function isScreenshot(name) {
  return /^\d{2}_/.test(name);
}

function figure(name, caption, note = '') {
  const src = !isScreenshot(name) || USE_SCREENSHOTS ? imgData(name) : '';
  if (!src) {
    return `
      <figure class="placeholder-figure">
        <div class="screenshot-placeholder">
          <div class="phone-frame">
            <div class="phone-notch"></div>
            <div class="phone-content">
              <div class="screen-line wide"></div>
              <div class="screen-line"></div>
              <div class="screen-card"></div>
              <div class="screen-line short"></div>
              <strong>Chèn screenshot mobile sau</strong>
            </div>
          </div>
        </div>
        <figcaption>${caption}${note ? ` - ${note}` : ''}</figcaption>
      </figure>`;
  }
  return `
    <figure>
      <img src="${src}" alt="${caption}" />
      <figcaption>${caption}</figcaption>
    </figure>`;
}

const html = `<!doctype html>
<html lang="vi">
<head>
  <meta charset="utf-8" />
  <title>Báo cáo kỹ thuật DevConnect Mobile</title>
  <style>
    @page { size: A4; margin: 18mm 16mm 18mm 20mm; }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      font-family: "Times New Roman", "DejaVu Serif", serif;
      color: #111827;
      font-size: 12pt;
      line-height: 1.45;
      background: #ffffff;
    }
    .page {
      min-height: 261mm;
      page-break-after: always;
      position: relative;
    }
    .page:last-child { page-break-after: auto; }
    .cover {
      min-height: 261mm;
      display: flex;
      flex-direction: column;
      justify-content: space-between;
      text-align: center;
      padding: 10mm 0 0;
    }
    .school {
      text-transform: uppercase;
      font-weight: 700;
      line-height: 1.55;
    }
    .cover-title {
      margin-top: 34mm;
      border: 2px solid #1d4ed8;
      padding: 18mm 10mm;
    }
    .cover-title h1 {
      margin: 0 0 8mm;
      color: #1d4ed8;
      border: 0;
      font-size: 26pt;
      text-transform: uppercase;
    }
    .cover-title h2 {
      margin: 0;
      color: #0f172a;
      font-size: 18pt;
      text-transform: uppercase;
    }
    .cover-meta {
      width: 78%;
      margin: 24mm auto 0;
      text-align: left;
      line-height: 1.9;
      font-size: 12pt;
    }
    .cover-footer { margin-top: auto; font-size: 12pt; }
    h1, h2, h3 { page-break-after: avoid; }
    h1 {
      margin: 0 0 11mm;
      padding-bottom: 4mm;
      border-bottom: 2px solid #1d4ed8;
      color: #0f172a;
      font-size: 20pt;
      text-transform: uppercase;
    }
    h2 {
      margin: 8mm 0 3mm;
      color: #1e3a8a;
      font-size: 15pt;
    }
    h3 {
      margin: 6mm 0 2mm;
      color: #0f172a;
      font-size: 13pt;
    }
    p { margin: 0 0 3.5mm; text-align: justify; }
    ul, ol { margin-top: 2mm; margin-bottom: 4mm; }
    li { margin-bottom: 1.4mm; }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 4mm 0 6mm;
      font-size: 10.2pt;
      page-break-inside: avoid;
    }
    th {
      background: #1d4ed8;
      color: #ffffff;
      border: 1px solid #1e3a8a;
      padding: 6px 7px;
      text-align: left;
      vertical-align: top;
    }
    td {
      border: 1px solid #cbd5e1;
      padding: 6px 7px;
      vertical-align: top;
    }
    tr:nth-child(even) td { background: #f8fafc; }
    code {
      font-family: "Consolas", monospace;
      font-size: 10pt;
      background: #eef2ff;
      color: #1e3a8a;
      padding: 1px 3px;
      border-radius: 3px;
    }
    .toc {
      list-style: none;
      padding: 0;
      margin: 0;
      font-size: 12.5pt;
      line-height: 1.9;
    }
    .toc li {
      display: flex;
      border-bottom: 1px dotted #94a3b8;
      gap: 8px;
    }
    .toc span:first-child { font-weight: 700; color: #1d4ed8; }
    .callout {
      border-left: 4px solid #1d4ed8;
      background: #eff6ff;
      padding: 8px 10px;
      margin: 4mm 0;
      color: #1e3a8a;
      page-break-inside: avoid;
    }
    .two-col {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 8mm;
      align-items: start;
    }
    figure {
      margin: 5mm 0 7mm;
      text-align: center;
      page-break-inside: avoid;
    }
    figure img {
      max-width: 100%;
      max-height: 136mm;
      border: 1px solid #cbd5e1;
      border-radius: 8px;
    }
    figcaption {
      margin-top: 2mm;
      font-size: 10pt;
      font-style: italic;
      color: #475569;
    }
    .screenshot-placeholder {
      min-height: 118mm;
      display: flex;
      align-items: center;
      justify-content: center;
      background: linear-gradient(145deg, #eef6ff, #f8fafc);
      border: 1px dashed #94a3b8;
      border-radius: 12px;
      padding: 8mm;
    }
    .phone-frame {
      width: 46mm;
      min-height: 96mm;
      border: 2px solid #1e293b;
      border-radius: 8mm;
      background: #ffffff;
      padding: 7mm 4mm 5mm;
      position: relative;
      box-shadow: 0 12px 28px rgba(15, 23, 42, 0.14);
    }
    .phone-notch {
      position: absolute;
      top: 3mm;
      left: 50%;
      transform: translateX(-50%);
      width: 16mm;
      height: 2.4mm;
      border-radius: 999px;
      background: #1e293b;
    }
    .phone-content {
      height: 82mm;
      border-radius: 5mm;
      background: #f1f5f9;
      padding: 7mm 4mm;
      color: #64748b;
      font-family: Arial, sans-serif;
      font-size: 10pt;
      display: flex;
      flex-direction: column;
      justify-content: center;
      gap: 4mm;
      text-align: center;
    }
    .screen-line {
      height: 2.8mm;
      width: 70%;
      background: #cbd5e1;
      border-radius: 999px;
      margin: 0 auto;
    }
    .screen-line.wide { width: 88%; }
    .screen-line.short { width: 48%; }
    .screen-card {
      height: 22mm;
      width: 86%;
      border-radius: 5mm;
      background: #dbeafe;
      margin: 0 auto;
    }
    .small-note {
      color: #64748b;
      font-style: italic;
      font-size: 10.5pt;
    }
  </style>
</head>
<body>
  <section class="page cover">
    <div class="school">
      FPT University<br />
      PRM393 - Mobile Application Development (Flutter)
    </div>
    <div class="cover-title">
      <h1>Báo Cáo Kỹ Thuật</h1>
      <h2>DevConnect Mobile</h2>
      <p style="text-align:center;margin-top:8mm;">Ứng dụng mobile cho cộng đồng lập trình viên</p>
    </div>
    <div class="cover-meta">
      <div><strong>Nhóm:</strong> [Điền tên nhóm]</div>
      <div><strong>Thành viên:</strong> [Điền họ tên và MSSV của 4 thành viên]</div>
      <div><strong>Giảng viên:</strong> [Điền tên giảng viên]</div>
      <div><strong>Giai đoạn:</strong> Bài giữa kỳ PRM393</div>
      <div><strong>Công nghệ chính:</strong> Flutter, Dart, SQLite, Repository Pattern</div>
    </div>
    <div class="cover-footer">TP. Hồ Chí Minh, 2026</div>
  </section>

  <section class="page">
    <h1>Mục Lục</h1>
    <ol class="toc">
      <li><span>1.</span><span>Giới thiệu nhóm</span></li>
      <li><span>2.</span><span>Nghiên cứu tình huống</span></li>
      <li><span>3.</span><span>Phân tích nghiệp vụ và thiết kế hệ thống</span></li>
      <li><span>4.</span><span>Yêu cầu phát triển</span></li>
      <li><span>5.</span><span>Demo ứng dụng mobile</span></li>
      <li><span>6.</span><span>Kết luận và thảo luận</span></li>
      <li><span>7.</span><span>Đánh giá đóng góp thành viên</span></li>
    </ol>
    <h2>Tóm tắt báo cáo</h2>
    <p>
      DevConnect Mobile là ứng dụng Flutter hướng tới cộng đồng lập trình viên, giúp người dùng chia sẻ bài viết kỹ thuật, xây dựng hồ sơ, trao đổi qua chat, khám phá dự án, việc làm và bảng xếp hạng. Trong khuôn khổ giữa kỳ, dự án tập trung vào MVP có thể demo bằng dữ liệu local SQLite, đồng thời có thêm backend API prototype chạy riêng bằng Node.js + SQLite server-side để chuẩn bị refactor sau midterm. Những màn chưa dùng để chấm giữa kỳ sẽ được đánh dấu là “đang phát triển” để phục vụ lộ trình sau này.
    </p>
    <div class="callout">
      Phạm vi báo cáo bám theo DOCX gốc: Team Introduction, Case Study, Business Analysis/System Design, Development Requirements, Demo, Conclusion and Discussion, Contribution.
    </div>
  </section>

  <section class="page">
    <h1>1. Giới Thiệu Nhóm</h1>
    <h2>1.1. Thông tin dự án</h2>
    <table>
      <tr><th>Hạng mục</th><th>Nội dung</th></tr>
      <tr><td>Tên dự án</td><td>DevConnect Mobile</td></tr>
      <tr><td>Môn học</td><td>PRM393 - Mobile Application Development (Flutter)</td></tr>
      <tr><td>Loại bài</td><td>Project giữa kỳ</td></tr>
      <tr><td>Repo làm việc</td><td><code>P:\\midterm-mobile</code></td></tr>
      <tr><td>Repo tham chiếu dài hạn</td><td><code>P:\\social-dev</code></td></tr>
    </table>

    <h2>1.2. Thành viên và trách nhiệm</h2>
    <table>
      <tr><th>Thành viên</th><th>Vai trò đề xuất</th><th>Đóng góp chính</th></tr>
      <tr><td>[Thành viên 1]</td><td>Trưởng nhóm kỹ thuật</td><td>Kiến trúc app, SQLite, repository, luồng dữ liệu.</td></tr>
      <tr><td>[Thành viên 2]</td><td>UI/UX developer</td><td>Feed, profile, explore, reusable widgets, visual consistency.</td></tr>
      <tr><td>[Thành viên 3]</td><td>Feature developer</td><td>Chat, projects, jobs, leaderboard, notifications.</td></tr>
      <tr><td>[Thành viên 4]</td><td>Kiểm thử và tài liệu</td><td>Kiểm thử, report PDF, slide PPTX, kịch bản demo, checklist bản phát hành.</td></tr>
    </table>
    <p class="small-note">Ghi chú: thay phần giữ chỗ bằng họ tên thật, MSSV và phần trăm đóng góp trước khi nộp.</p>
  </section>

  <section class="page">
    <h1>2. Nghiên Cứu Tình Huống</h1>
    <h2>2.1. Bối cảnh kinh doanh</h2>
    <p>
      Sinh viên CNTT và junior developer thường phải dùng nhiều nền tảng khác nhau cho học tập, networking, chia sẻ bài viết, tìm dự án, tìm việc và trao đổi kỹ thuật. Trải nghiệm này bị phân mảnh, khiến người dùng khó xây dựng hồ sơ kỹ thuật xuyên suốt và khó tìm cơ hội phù hợp.
    </p>
    ${figure('problem_fragmentation.png', 'Hình 1. Vấn đề phân mảnh trong quy trình làm việc của developer')}

    <h2>2.2. Giải pháp đề xuất</h2>
    <p>
      DevConnect Mobile đề xuất một nền tảng mobile thống nhất cho cộng đồng lập trình viên. Người dùng có thể xem feed bài viết, tạo nội dung, bình luận, xem hồ sơ, chat cơ bản, xem dự án, xem việc làm và leaderboard. Các hướng lớn hơn như analytics, mentorship, playground, live code, recommendation và AI được giữ lại theo scope <code>social-dev</code> nhưng chuyển sang trạng thái đang phát triển trong phase giữa kỳ.
    </p>
    ${figure('solution_unified.png', 'Hình 2. Hướng giải pháp thống nhất của DevConnect Mobile')}

    <h2>2.3. Đối tượng người dùng</h2>
    <table>
      <tr><th>Nhóm người dùng</th><th>Nhu cầu</th><th>Chức năng liên quan</th></tr>
      <tr><td>Sinh viên CNTT</td><td>Học hỏi, đăng bài, tìm project, xây dựng hồ sơ.</td><td>Feed, Create Post, Profile, Projects.</td></tr>
      <tr><td>Junior developer</td><td>Tìm cơ hội việc làm, mở rộng network, hỏi đáp kỹ thuật.</td><td>Jobs, Chat, Explore, Leaderboard.</td></tr>
      <tr><td>Mentor / lập trình viên kinh nghiệm</td><td>Chia sẻ kinh nghiệm, hỗ trợ cộng đồng, tìm nhân tài.</td><td>Mentorship, Analytics, lộ trình tương lai.</td></tr>
    </table>
  </section>

  <section class="page">
    <h1>3. Phân Tích Nghiệp Vụ Và Thiết Kế Hệ Thống</h1>
    <h2>3.1. Phân tách scope</h2>
    <table>
      <tr><th>Nhóm chức năng</th><th>Module</th><th>Cách trình bày trong giữa kỳ</th></tr>
      <tr><td>MVP chính</td><td>Feed, chi tiết bài viết, tạo bài viết, hồ sơ, khám phá, chat cơ bản, dự án, việc làm, bảng xếp hạng</td><td>Trình bày là đã implement hoặc có luồng local rõ ràng.</td></tr>
      <tr><td>Basic demo</td><td>Login, Register, Settings, Notifications Basic</td><td>Trình bày là local/demo, chưa claim backend auth hoặc notification service.</td></tr>
      <tr><td>Đang phát triển</td><td>Analytics, Playground, Live Code, Mentorship, Recommendation, AI</td><td>Giữ UI từ định hướng <code>social-dev</code>, nhưng không claim realtime/AI thật. Backend hiện là prototype chạy riêng.</td></tr>
    </table>
    ${figure('scope_comparison.png', 'Hình 3. Phân tách midterm MVP và full-scope social-dev')}

    <h2>3.2. Yêu cầu chức năng</h2>
    <table>
      <tr><th>ID</th><th>Yêu cầu chức năng</th><th>Trạng thái</th></tr>
      <tr><td>FR-01</td><td>Người dùng có thể đăng nhập/đăng ký bằng luồng demo local.</td><td>Đã có UI/luồng cơ bản.</td></tr>
      <tr><td>FR-02</td><td>Người dùng có thể xem feed bài viết.</td><td>Đã kết nối repository/SQLite.</td></tr>
      <tr><td>FR-03</td><td>Người dùng có thể tạo bài viết mới.</td><td>Có CRUD local.</td></tr>
      <tr><td>FR-04</td><td>Người dùng có thể xem chi tiết bài viết và thêm bình luận.</td><td>Có CRUD local.</td></tr>
      <tr><td>FR-05</td><td>Người dùng có thể xem hồ sơ, khám phá nội dung và leaderboard.</td><td>Đã có dữ liệu local/browse.</td></tr>
      <tr><td>FR-06</td><td>Người dùng có thể mở danh sách chat và gửi tin nhắn cơ bản.</td><td>Có CRUD local cho message.</td></tr>
      <tr><td>FR-07</td><td>Người dùng có thể xem project marketplace và job board.</td><td>Browse bằng dữ liệu seed chọn lọc.</td></tr>
      <tr><td>FR-08</td><td>Người dùng có thể mở các màn xem trước cho tương lai.</td><td>Đang phát triển, không claim backend/realtime/AI.</td></tr>
    </table>

    <h2>3.3. Yêu cầu phi chức năng</h2>
    <ul>
      <li>Giao diện nhất quán, có khả năng demo trên thiết bị hoặc emulator.</li>
      <li>Data access đi qua repository, không query SQLite trực tiếp trong UI.</li>
      <li>Ứng dụng hoạt động local-first trong phase giữa kỳ.</li>
      <li>Thiết kế giữ khả năng nâng cấp sang backend API và Docker services sau midterm. Repo đã có backend API prototype chạy riêng để chuẩn bị phase này.</li>
      <li>Có ít nhất 1 unit test và 1 widget test theo yêu cầu môn học.</li>
    </ul>
  </section>

  <section class="page">
    <h1>3. Phân Tích Nghiệp Vụ Và Thiết Kế Hệ Thống</h1>
    <h2>3.4. Kiến trúc ứng dụng</h2>
    <p>
      Ứng dụng đi theo kiến trúc phân lớp. Flutter Screens và Shared Widgets chỉ phụ trách hiển thị và tương tác. Repository phụ trách đọc/ghi dữ liệu cho từng module. SQLite là local database trong Flutter app ở phase giữa kỳ. Repo cũng có backend API prototype dùng SQLite server-side để chuẩn bị phase sau. Cách tách này giúp sau midterm có thể bổ sung remote datasource hoặc backend API mà không phải viết lại toàn bộ UI.
    </p>
    ${figure('architecture_layers.png', 'Hình 4. Kiến trúc phân lớp Flutter UI - Repository - SQLite')}

    <h2>3.5. Thiết kế database/API</h2>
    <table>
      <tr><th>Bảng</th><th>Vai trò</th><th>Ghi chú</th></tr>
      <tr><td>users</td><td>Thông tin hồ sơ người dùng.</td><td>Dùng cho profile, author, leaderboard.</td></tr>
      <tr><td>posts</td><td>Bài viết trong feed.</td><td>Luồng nội dung chính.</td></tr>
      <tr><td>comments</td><td>Bình luận của bài viết.</td><td>CRUD local khi demo post detail.</td></tr>
      <tr><td>conversations</td><td>Metadata hội thoại.</td><td>Dùng cho danh sách chat.</td></tr>
      <tr><td>messages</td><td>Nội dung tin nhắn.</td><td>CRUD local khi gửi tin nhắn.</td></tr>
      <tr><td>projects</td><td>Danh sách project marketplace.</td><td>Seed chọn lọc để browse.</td></tr>
      <tr><td>jobs</td><td>Danh sách job board.</td><td>Seed chọn lọc để browse.</td></tr>
      <tr><td>notifications</td><td>Thông báo local.</td><td>Basic read/empty state.</td></tr>
    </table>
    ${figure('data_strategy.png', 'Hình 5. Chiến lược dữ liệu SQLite-first')}

    <h2>3.6. Công nghệ mới/ngoài phạm vi cơ bản</h2>
    <table>
      <tr><th>Công nghệ</th><th>Mục đích</th><th>Lý do chọn</th></tr>
      <tr><td>SQLite / sqflite</td><td>Local database</td><td>Phù hợp mobile local-first, không cần backend trong giữa kỳ.</td></tr>
      <tr><td>Repository Pattern</td><td>Tách data layer khỏi UI</td><td>Dễ refactor sang API/backend sau midterm.</td></tr>
      <tr><td>go_router</td><td>Điều hướng nhiều màn hình</td><td>Quản lý route rõ ràng cho app nhiều module.</td></tr>
      <tr><td>pptxgenjs / Puppeteer</td><td>Sinh slide và report</td><td>Tự động hóa deliverables, dễ cập nhật layout/nội dung.</td></tr>
      <tr><td>Backend prototype</td><td>Node.js + SQLite server-side</td><td>Cung cấp API chạy riêng cho users, posts, comments, chat, projects, jobs, leaderboard và notifications.</td></tr>
      <tr><td>Docker sau midterm</td><td>Container hóa backend services</td><td>Chỉ phù hợp khi có database server, worker/realtime services hoặc môi trường dev/staging phức tạp hơn.</td></tr>
    </table>
  </section>

  <section class="page">
    <h1>4. Yêu Cầu Phát Triển</h1>
    <h2>4.1. UI Implementation</h2>
    <p>
      Ứng dụng giữ đầy đủ nhóm màn hình từ định hướng <code>social-dev</code>. Những màn nằm trong MVP chính được dùng để demo giữa kỳ; các màn chưa đủ backend/realtime/AI được chuyển sang trạng thái đang phát triển để bảo toàn lộ trình.
    </p>
    <table>
      <tr><th>Nhóm UI</th><th>Màn hình</th><th>Trạng thái</th></tr>
      <tr><td>Xác thực</td><td>Đăng nhập, đăng ký, onboarding</td><td>Luồng demo/local.</td></tr>
      <tr><td>Nội dung</td><td>Trang chủ feed, tạo bài viết, chi tiết bài viết, khám phá</td><td>MVP chính.</td></tr>
      <tr><td>Cộng đồng</td><td>Hồ sơ, danh sách chat, chi tiết chat, thông báo</td><td>MVP chính/cơ bản.</td></tr>
      <tr><td>Opportunity</td><td>Project Marketplace, Job Board, Leaderboard</td><td>Browse trong MVP.</td></tr>
      <tr><td>Tương lai</td><td>Analytics, Playground, Live Code, Mentorship</td><td>Đang phát triển.</td></tr>
    </table>

    <h2>4.2. State Management và Data Handling</h2>
    <p>
      Ở phase giữa kỳ, trọng tâm là luồng dữ liệu local rõ ràng. UI gọi repository; repository làm việc với SQLite. Chỉ các bảng cần bootstrap mới dùng seed data. Những luồng CRUD chính như tạo bài viết, thêm bình luận và gửi tin nhắn phải được kiểm tra trực tiếp trong app.
    </p>

    <h2>4.3. Local hoặc Remote Database</h2>
    <p>
      Dự án chọn SQLite local database cho Flutter app. Đây là lựa chọn hợp lý cho midterm vì app có thể demo độc lập, không phụ thuộc network hoặc server. Bên cạnh đó, repo có backend prototype dùng SQLite server-side để chứng minh hướng API backend và chuẩn bị cho giai đoạn nối remote datasource sau midterm.
    </p>

    <h2>4.4. Deployment Requirement</h2>
    <table>
      <tr><th>Yêu cầu</th><th>Tình trạng</th><th>Ghi chú</th></tr>
      <tr><td>Build APK/AppBundle bản phát hành</td><td>Đã build thành công</td><td>Lệnh đã chạy: <code>flutter build apk --release</code>. File đầu ra: <code>app/build/app/outputs/flutter-apk/app-release.apk</code>, khoảng 22.4MB.</td></tr>
      <tr><td>Minh chứng bản phát hành</td><td>Đã có file build</td><td>Nếu giảng viên yêu cầu ảnh minh chứng, chụp lại terminal báo build thành công hoặc màn hình app chạy bản phát hành.</td></tr>
      <tr><td>Nén source code</td><td>Cần đóng gói khi nộp</td><td>Zip toàn bộ Flutter project, không zip cache/build không cần thiết.</td></tr>
    </table>

    <h2>4.5. Yêu cầu kiểm thử</h2>
    <table>
      <tr><th>Loại test</th><th>File</th><th>Mục đích</th></tr>
      <tr><td>Unit test</td><td><code>app/test/unit/user_repository_test.dart</code></td><td>Kiểm tra ánh xạ dữ liệu user.</td></tr>
      <tr><td>Widget test</td><td><code>app/test/widget/login_screen_test.dart</code></td><td>Kiểm tra màn login hiển thị field/CTA cơ bản.</td></tr>
      <tr><td>Kiểm thử thủ công</td><td>Chạy trực tiếp trên emulator/device</td><td>Kiểm tra tạo bài viết, thêm bình luận, gửi tin nhắn, duyệt module.</td></tr>
    </table>
  </section>

  <section class="page">
    <h1>5. Demo Ứng Dụng Mobile</h1>
    <h2>5.1. Kịch bản demo đề xuất</h2>
    <ol>
      <li>Login local demo và vào Home Feed.</li>
      <li>Mở Feed, xem danh sách bài viết từ SQLite.</li>
      <li>Tạo bài viết mới và quay lại feed để kiểm tra dữ liệu.</li>
      <li>Mở Post Detail, thêm bình luận để kiểm tra CRUD local.</li>
      <li>Mở Profile, Explore, Project Marketplace, Job Board và Leaderboard.</li>
      <li>Mở Chat, gửi một tin nhắn mới để kiểm tra message local.</li>
      <li>Mở Analytics, Playground, Mentorship, Live Code và nói rõ đây là màn đang phát triển.</li>
    </ol>

    <h2>5.2. Luồng nội dung chính</h2>
    <div class="two-col">
      <div>${figure('04_home_feed.png', 'Hình 6. Trang chủ feed', 'ảnh màn hình sẽ lắp sau')}</div>
      <div>${figure('08_create_post.png', 'Hình 7. Tạo bài viết', 'ảnh màn hình sẽ lắp sau')}</div>
    </div>
    <div class="two-col">
      <div>${figure('05_post_detail.png', 'Hình 8. Chi tiết bài viết và bình luận', 'ảnh màn hình sẽ lắp sau')}</div>
      <div>${figure('06_explore.png', 'Hình 9. Khám phá nội dung', 'ảnh màn hình sẽ lắp sau')}</div>
    </div>
  </section>

  <section class="page">
    <h1>5. Demo Ứng Dụng Mobile</h1>
    <h2>5.3. Luồng cộng đồng và cơ hội</h2>
    <div class="two-col">
      <div>${figure('07_profile.png', 'Hình 10. Hồ sơ người dùng', 'ảnh màn hình sẽ lắp sau')}</div>
      <div>${figure('09_direct_message.png', 'Hình 11. Chi tiết chat', 'ảnh màn hình sẽ lắp sau')}</div>
    </div>
    <div class="two-col">
      <div>${figure('12_project_marketplace.png', 'Hình 12. Sàn dự án', 'ảnh màn hình sẽ lắp sau')}</div>
      <div>${figure('13_job_board.png', 'Hình 13. Bảng việc làm', 'ảnh màn hình sẽ lắp sau')}</div>
    </div>

    <h2>5.4. Module tương lai đang phát triển</h2>
    <p>
      Những màn sau được giữ lại để thể hiện full-scope từ <code>social-dev</code>, nhưng trong demo giữa kỳ phải giới thiệu là đang phát triển cho phase sau: Analytics, Playground, Mentorship và Live Code.
    </p>
    <div class="two-col">
      <div>${figure('15_analytics.png', 'Hình 14. Analytics đang phát triển', 'ảnh màn hình sẽ lắp sau')}</div>
      <div>${figure('17_mentorship.png', 'Hình 15. Mentorship đang phát triển', 'ảnh màn hình sẽ lắp sau')}</div>
    </div>
  </section>

  <section class="page">
    <h1>6. Kết Luận Và Thảo Luận</h1>
    <h2>6.1. Ưu điểm</h2>
    <ul>
      <li>Phạm vi giữa kỳ rõ ràng, có thể demo bằng luồng dữ liệu local.</li>
      <li>Giữ đầy đủ hướng sản phẩm từ <code>social-dev</code> nên không mất lộ trình sau midterm.</li>
      <li>Repository layer giúp giảm phụ thuộc trực tiếp giữa UI và SQLite.</li>
      <li>SQLite phù hợp với mobile app giữa kỳ vì không cần server để demo.</li>
      <li>Docs, PDF và PPTX được chuẩn hóa theo cấu trúc nộp bài.</li>
    </ul>

    <h2>6.2. Hạn chế</h2>
    <ul>
      <li>Xác thực hiện mới là luồng demo/local, chưa có backend session thật.</li>
      <li>Chat chưa realtime; Live Code, Mentorship, Analytics, AI và Recommendation chỉ là phạm vi tương lai.</li>
      <li>Backend hiện mới là prototype chạy riêng, chưa phải runtime mặc định của Flutter app.</li>
      <li>APK phát hành và ảnh minh chứng cần chạy/chụp sau khi kiểm tra app local.</li>
      <li>Độ phủ kiểm thử mới ở mức nền tảng, cần bổ sung test cho các luồng CRUD quan trọng.</li>
    </ul>

    <h2>6.3. Kiến thức rút ra</h2>
    <p>
      Qua project này, nhóm rút ra cách giới hạn scope theo phase, cách thiết kế data layer local-first bằng SQLite, cách tách UI khỏi repository và cách trình bày trung thực giữa phần đã implement với phần đang phát triển. Backend prototype giúp nhóm có bước đệm API thật, nhưng vẫn giữ demo Flutter giữa kỳ ổn định. Đây là nền tảng để sau midterm có thể refactor dần lên backend hoàn chỉnh, Docker services, realtime, analytics và AI/recommendation theo hướng <code>social-dev</code>.
    </p>

    <h2>6.4. Hướng phát triển nếu có thêm thời gian</h2>
    <ul>
      <li>Chạy full local verification, sửa bug runtime và build release APK.</li>
      <li>Chuẩn hóa quản lý trạng thái cho các luồng chính.</li>
      <li>Nối Flutter repository sang backend API prototype, sau đó nâng cấp database server và Docker Compose khi cần.</li>
      <li>Nâng cấp chat realtime, live code, mentorship matching, analytics và recommendation/AI.</li>
      <li>Bổ sung độ phủ kiểm thử cho tạo bài viết, bình luận, gửi tin nhắn, dự án/việc làm và thông báo.</li>
    </ul>
  </section>

  <section class="page">
    <h1>7. Đánh Giá Đóng Góp Thành Viên</h1>
    <p>
      Bảng dưới đây theo đúng tinh thần đánh giá đóng góp trong DOCX gốc. Nhóm cần thay phần giữ chỗ bằng họ tên thật và phần trăm thật trước khi nộp.
    </p>
    <table>
      <tr><th>Hạng mục</th><th>Team</th><th>Thành viên 1</th><th>Thành viên 2</th><th>Thành viên 3</th><th>Thành viên 4</th></tr>
      <tr><td>Case Study Analysis</td><td>100%</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td></tr>
      <tr><td>Business Analysis</td><td>100%</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td></tr>
      <tr><td>System Design</td><td>100%</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td></tr>
      <tr><td>Implementation</td><td>100%</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td></tr>
      <tr><td>Documentation</td><td>100%</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td><td>[Điền]</td></tr>
    </table>

    <h2>Checklist trước khi nộp</h2>
    <table>
      <tr><th>Việc cần làm</th><th>Trạng thái</th><th>Ghi chú</th></tr>
      <tr><td>Điền tên thành viên, MSSV, giảng viên, lớp</td><td>Cần điền</td><td>Áp dụng cho PDF và PPTX.</td></tr>
      <tr><td>Lắp ảnh màn hình mobile thật</td><td>Làm sau khi chạy app</td><td>Hiện PDF/PPTX dùng khung giữ chỗ.</td></tr>
      <tr><td>Chạy <code>flutter test</code></td><td>Đã pass</td><td>2/2 tests passed ở thời điểm chuẩn bị deliverables.</td></tr>
      <tr><td>Build APK bản phát hành</td><td>Đã build</td><td>APK bản phát hành đã sinh tại <code>app/build/app/outputs/flutter-apk/app-release.apk</code>.</td></tr>
      <tr><td>Zip source code</td><td>Cần làm khi nộp</td><td>Không zip cache/build không cần thiết.</td></tr>
    </table>
  </section>
</body>
</html>`;

async function main() {
  const browser = await puppeteer.launch({
    headless: 'new',
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
  });
  const page = await browser.newPage();
  await page.setContent(html, { waitUntil: 'networkidle0' });
  await page.pdf({
    path: OUT,
    format: 'A4',
    printBackground: true,
    margin: { top: '0mm', right: '0mm', bottom: '0mm', left: '0mm' },
    displayHeaderFooter: false,
  });
  await browser.close();
  console.log(`Generated ${OUT}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
