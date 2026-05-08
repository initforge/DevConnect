const fs = require('fs');
const path = require('path');
const PptxGenJS = require('pptxgenjs');

const pptx = new PptxGenJS();
pptx.layout = 'LAYOUT_WIDE';
pptx.author = 'DevConnect Team';
pptx.subject = 'Bài thuyết trình giữa kỳ PRM393';
pptx.title = 'DevConnect Mobile - Báo cáo giữa kỳ';
pptx.company = 'FPT University';
pptx.lang = 'vi-VN';
pptx.theme = {
  headFontFace: 'Aptos Display',
  bodyFontFace: 'Aptos',
  lang: 'vi-VN',
};
pptx.defineLayout({ name: 'LAYOUT_WIDE', width: 13.333, height: 7.5 });
pptx.layout = 'LAYOUT_WIDE';

const OUT = path.join(__dirname, 'DevConnect_Midterm_Presentation_PRM393.pptx');
const ASSETS = path.join(__dirname, 'assets');
const SHOTS = path.join(ASSETS, 'screenshots');
const ACTUAL_SHOTS = path.join(ASSETS, 'mobile-screenshots');
const USE_SCREENSHOTS = true;

const W = 13.333;
const H = 7.5;
const C = {
  ink: '102033',
  ink2: '334155',
  muted: '64748B',
  paper: 'F8FAFC',
  white: 'FFFFFF',
  blue: '2563EB',
  cyan: '06B6D4',
  mint: '14B8A6',
  lime: '84CC16',
  amber: 'F59E0B',
  rose: 'F43F5E',
  violet: '7C3AED',
  navy: '0F172A',
  border: 'D8E2EF',
  softBlue: 'EAF2FF',
  softMint: 'E6FFFA',
  softAmber: 'FFF7E6',
  softViolet: 'F3E8FF',
};

function asset(name) {
  const base = name.replace(/\.png$/i, '');
  const actual = path.join(ACTUAL_SHOTS, `${base}_actual.png`);
  if (fs.existsSync(actual)) return actual;
  const direct = path.join(ASSETS, name);
  const shot = path.join(SHOTS, name);
  if (fs.existsSync(direct)) return direct;
  if (fs.existsSync(shot)) return shot;
  return null;
}

function addBg(slide, variant = 'light') {
  slide.background = { color: variant === 'dark' ? C.navy : C.paper };
  if (variant === 'dark') {
    slide.addShape(pptx.ShapeType.ellipse, {
      x: -1.2, y: -0.6, w: 5.8, h: 5.8,
      fill: { color: C.blue, transparency: 55 },
      line: { transparency: 100 },
      rotate: 30,
    });
    slide.addShape(pptx.ShapeType.ellipse, {
      x: 8.7, y: 3.2, w: 5.8, h: 5.8,
      fill: { color: C.mint, transparency: 62 },
      line: { transparency: 100 },
      rotate: -10,
    });
  } else {
    slide.addShape(pptx.ShapeType.ellipse, {
      x: -1.6, y: -1.2, w: 5.4, h: 5.4,
      fill: { color: C.softBlue, transparency: 10 },
      line: { transparency: 100 },
      rotate: 20,
    });
    slide.addShape(pptx.ShapeType.ellipse, {
      x: 9.2, y: 4.2, w: 5.2, h: 5.2,
      fill: { color: C.softMint, transparency: 5 },
      line: { transparency: 100 },
      rotate: -18,
    });
  }
}

function addTitle(slide, eyebrow, title, subtitle) {
  if (eyebrow) {
    slide.addText(eyebrow.toUpperCase(), {
      x: 0.62, y: 0.35, w: 5.5, h: 0.24,
      fontSize: 8.5, bold: true, color: C.blue,
      charSpace: 1.2, margin: 0,
    });
  }
  slide.addText(title, {
    x: 0.6, y: 0.65, w: 8.6, h: 0.48,
    fontFace: 'Aptos Display', fontSize: 24, bold: true,
    color: C.ink, margin: 0, fit: 'shrink',
  });
  slide.addShape(pptx.ShapeType.rect, {
    x: 0.62, y: 1.18, w: 1.35, h: 0.055,
    fill: { color: C.mint },
    line: { color: C.mint },
  });
  if (subtitle) {
    slide.addText(subtitle, {
      x: 0.62, y: 1.35, w: 8.6, h: 0.36,
      fontSize: 10.5, color: C.muted, margin: 0, fit: 'shrink',
    });
  }
}

function footer(slide, n, dark = false) {
  slide.addText(`DevConnect Mobile | PRM393 | ${n}/20`, {
    x: 9.75, y: 7.08, w: 2.95, h: 0.22,
    fontSize: 8.2, color: dark ? 'CBD5E1' : C.muted,
    align: 'right', margin: 0,
  });
}

function pill(slide, text, x, y, color = C.blue, w = 1.25) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h: 0.34,
    rectRadius: 0.08,
    fill: { color },
    line: { color },
  });
  slide.addText(text, {
    x, y: y + 0.075, w, h: 0.15,
    fontSize: 7.6, bold: true, color: C.white,
    align: 'center', margin: 0, fit: 'shrink',
  });
}

function bulletList(slide, items, x, y, w, h, color = C.ink) {
  slide.addText(items.map((item) => ({
    text: item,
    options: { bullet: { type: 'bullet' }, breakLine: true, fontSize: 13, color, fit: 'shrink' },
  })), {
    x, y, w, h, margin: 0.05, breakLine: false,
    fit: 'shrink',
  });
}

function img(slide, name, x, y, w, h, opts = {}) {
  const file = asset(name);
  if (file) {
    slide.addImage({ path: file, x, y, w, h, ...opts });
    return true;
  }
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h, rectRadius: 0.08,
    fill: { color: 'E2E8F0' },
    line: { color: C.border, dash: 'dash' },
  });
  slide.addText(name, {
    x, y: y + h / 2 - 0.16, w, h: 0.32,
    fontSize: 9, color: C.muted, align: 'center', margin: 0,
  });
  return false;
}

function card(slide, x, y, w, h, fill = C.white) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x: x + 0.04, y: y + 0.06, w, h,
    rectRadius: 0.16,
    fill: { color: '0F172A', transparency: 90 },
    line: { transparency: 100 },
  });
  slide.addShape(pptx.ShapeType.roundRect, {
    x, y, w, h, rectRadius: 0.16,
    fill: { color: fill },
    line: { color: C.border, transparency: 20 },
  });
}

function metricCard(slide, x, y, title, value, note, color) {
  card(slide, x, y, 3.0, 1.18);
  slide.addShape(pptx.ShapeType.roundRect, {
    x: x + 0.22, y: y + 0.2, w: 0.16, h: 0.72,
    rectRadius: 0.03,
    fill: { color },
    line: { color },
  });
  slide.addText(value, {
    x: x + 0.52, y: y + 0.18, w: 2.15, h: 0.35,
    fontSize: 21, bold: true, color: C.ink, margin: 0,
  });
  slide.addText(title, {
    x: x + 0.52, y: y + 0.58, w: 2.1, h: 0.22,
    fontSize: 8.8, bold: true, color: C.muted, margin: 0,
  });
  slide.addText(note, {
    x: x + 0.52, y: y + 0.84, w: 2.1, h: 0.18,
    fontSize: 7.8, color: C.muted, margin: 0,
  });
}

function screenshot(slide, name, x, y, w, h, caption, badge) {
  slide.addShape(pptx.ShapeType.roundRect, {
    x: x - 0.07, y: y - 0.08, w: w + 0.14, h: h + 0.17,
    rectRadius: 0.2,
    fill: { color: C.white },
    line: { color: C.border },
  });
  if (USE_SCREENSHOTS) {
    img(slide, name, x, y, w, h);
  } else {
    slide.addShape(pptx.ShapeType.roundRect, {
      x, y, w, h, rectRadius: 0.16,
      fill: { color: 'EEF4FF' },
      line: { color: C.border, dash: 'dash' },
    });
    slide.addShape(pptx.ShapeType.ellipse, {
      x: x + w / 2 - 0.32, y: y + h / 2 - 0.62, w: 0.64, h: 0.64,
      fill: { color: C.white },
      line: { color: C.border },
    });
    slide.addText('APP', {
      x: x + w / 2 - 0.2, y: y + h / 2 - 0.5, w: 0.4, h: 0.25,
      fontSize: 8.5, bold: true, color: C.blue, align: 'center', margin: 0,
    });
    slide.addText('Chèn screenshot\nmobile sau', {
      x: x + 0.25, y: y + h / 2 + 0.05, w: w - 0.5, h: 0.55,
      fontSize: 10.2, bold: true, color: C.muted,
      align: 'center', margin: 0, fit: 'shrink',
    });
  }
  if (badge) pill(slide, badge, x + w - 1.12, y + 0.12, badge.includes('PHASE') ? C.violet : C.blue, 0.95);
  slide.addText(caption, {
    x: x - 0.05, y: y + h + 0.14, w: w + 0.1, h: 0.22,
    fontSize: 8.4, bold: true, color: C.ink2,
    align: 'center', margin: 0, fit: 'shrink',
  });
}

function sectionSlide(no, title, subtitle, color) {
  const s = pptx.addSlide();
  addBg(s, 'dark');
  slideNumber(s, no, color);
  s.addText(title, {
    x: 1.0, y: 2.52, w: 11.3, h: 0.65,
    fontSize: 34, bold: true, color: C.white,
    align: 'center', margin: 0, fit: 'shrink',
  });
  s.addText(subtitle, {
    x: 2.1, y: 3.34, w: 9.2, h: 0.45,
    fontSize: 14, color: 'DDE7F3',
    align: 'center', margin: 0, fit: 'shrink',
  });
  footer(s, no, true);
}

function slideNumber(slide, n, color) {
  slide.addShape(pptx.ShapeType.ellipse, {
    x: 5.88, y: 1.35, w: 1.6, h: 1.6,
    fill: { color, transparency: 15 },
    line: { color, transparency: 10 },
  });
  slide.addText(String(n).padStart(2, '0'), {
    x: 5.88, y: 1.77, w: 1.6, h: 0.42,
    fontSize: 20, bold: true, color: C.white,
    align: 'center', margin: 0,
  });
}

function addTableLike(slide, rows, x, y, w, rowH) {
  rows.forEach((row, i) => {
    const fill = i === 0 ? C.blue : C.white;
    card(slide, x, y + i * rowH, w, rowH - 0.08, fill);
    row.forEach((cell, j) => {
      const colW = [1.8, 2.2, w - 4.35][j];
      const colX = x + [0.25, 2.1, 4.15][j];
      slide.addText(cell, {
        x: colX, y: y + i * rowH + 0.18, w: colW, h: rowH - 0.36,
        fontSize: i === 0 ? 9.5 : 9.2,
        bold: i === 0 || j === 0,
        color: i === 0 ? C.white : (j === 0 ? C.blue : C.ink2),
        margin: 0, fit: 'shrink',
      });
    });
  });
}

function slide1() {
  const s = pptx.addSlide();
  addBg(s, 'dark');
  img(s, 'hero_devconnect.png', 0, 0, W, H);
  s.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: W, h: H, fill: { color: C.navy, transparency: 12 }, line: { transparency: 100 } });
  pill(s, 'PRM393 | MOBILE APPLICATION DEVELOPMENT', 4.55, 0.75, C.mint, 4.2);
  s.addText('DevConnect Mobile', {
    x: 0.8, y: 1.7, w: 11.7, h: 0.9,
    fontSize: 48, bold: true, color: C.white,
    align: 'center', margin: 0, fit: 'shrink',
  });
  s.addText('Báo cáo giữa kỳ | Flutter + SQLite | Backend prototype | Lộ trình social-dev', {
    x: 1.75, y: 2.75, w: 9.8, h: 0.38,
    fontSize: 16, color: 'E2E8F0',
    align: 'center', margin: 0,
  });
  s.addText('Nhóm: [Điền tên 4 thành viên]    |    Lớp: [Điền lớp]    |    GVHD: [Điền tên giảng viên]', {
    x: 1.2, y: 6.7, w: 10.95, h: 0.3,
    fontSize: 10.5, color: 'CBD5E1', align: 'center', margin: 0,
  });
  footer(s, 1, true);
}

function slide2() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Lộ trình trình bày', 'Agenda 15 phút', 'Chia nội dung để 4 người thuyết trình rõ vai trò, tránh nói lan man.');
  const steps = [
    ['01', 'Bối cảnh & tình huống', 'Vấn đề quy trình developer bị phân mảnh và giải pháp DevConnect.'],
    ['02', 'Thiết kế hệ thống', 'Kiến trúc Flutter, repository, SQLite local và backend prototype.'],
    ['03', 'Demo chức năng', 'MVP chính và các màn phạm vi đầy đủ chuyển sang đang phát triển.'],
    ['04', 'Kiểm thử & lộ trình', 'Kiểm thử nền tảng, checklist bản phát hành, kết luận và hướng nâng cấp.'],
  ];
  steps.forEach((it, i) => {
    const x = 0.75 + i * 3.1;
    card(s, x, 2.0, 2.65, 3.75);
    s.addText(it[0], { x: x + 0.2, y: 2.22, w: 0.7, h: 0.36, fontSize: 18, bold: true, color: [C.blue, C.mint, C.violet, C.amber][i], margin: 0 });
    s.addText(it[1], { x: x + 0.2, y: 2.85, w: 2.2, h: 0.48, fontSize: 16, bold: true, color: C.ink, margin: 0, fit: 'shrink' });
    s.addText(it[2], { x: x + 0.2, y: 3.65, w: 2.2, h: 1.2, fontSize: 10.6, color: C.muted, margin: 0, fit: 'shrink' });
  });
  footer(s, 2);
}

function slide3() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Case study', 'Vấn đề nghiệp vụ', 'Sinh viên CNTT và junior developer phải tách rời học tập, networking, dự án, việc làm và chat.');
  img(s, 'problem_fragmentation.png', 6.55, 1.35, 5.75, 4.75);
  bulletList(s, [
    'Thông tin nghề nghiệp bị phân tán ở nhiều nền tảng khác nhau.',
    'Khó thể hiện hồ sơ kỹ thuật xuyên suốt khi học, làm dự án và tìm việc.',
    'Cần một mobile app có thể demo đầy đủ luồng chính trong khuôn khổ PRM393.',
    'Full-scope vẫn giữ tầm nhìn social-dev để phát triển tiếp sau giữa kỳ.',
  ], 0.85, 2.0, 5.35, 3.4);
  metricCard(s, 0.85, 5.65, 'Đối tượng chính', '3 nhóm', 'Sinh viên, junior, mentor', C.blue);
  metricCard(s, 4.1, 5.65, 'Mục tiêu demo', 'MVP', 'Luồng chính chạy local', C.mint);
  footer(s, 3);
}

function slide4() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Giải pháp', 'DevConnect Mobile', 'Một nền tảng mobile thống nhất cho cộng đồng lập trình viên.');
  img(s, 'solution_unified.png', 0.75, 1.35, 5.8, 4.8);
  const items = [
    ['Feed', 'Chia sẻ bài viết, TIL, snippet, câu hỏi kỹ thuật.'],
    ['Profile', 'Thể hiện kỹ năng, hoạt động và danh tính developer.'],
    ['Community', 'Chat, leaderboard, projects, jobs, notifications.'],
    ['Tương lai', 'Analytics, mentorship, playground, live code, AI/recommendation.'],
  ];
  items.forEach((item, i) => {
    const y = 1.55 + i * 1.05;
    card(s, 7.0, y, 5.45, 0.82, [C.softBlue, C.softMint, C.softAmber, C.softViolet][i]);
    slideNumberSmall(s, item[0], 7.25, y + 0.18, [C.blue, C.mint, C.amber, C.violet][i]);
    s.addText(item[1], { x: 8.35, y: y + 0.22, w: 3.75, h: 0.32, fontSize: 10.6, color: C.ink2, margin: 0, fit: 'shrink' });
  });
  footer(s, 4);
}

function slideNumberSmall(slide, text, x, y, color) {
  slide.addShape(pptx.ShapeType.roundRect, { x, y, w: 0.88, h: 0.34, rectRadius: 0.08, fill: { color }, line: { color } });
  slide.addText(text, { x, y: y + 0.08, w: 0.88, h: 0.14, fontSize: 7, bold: true, color: C.white, align: 'center', margin: 0, fit: 'shrink' });
}

function slide5() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Scope', 'Copy full hướng tính năng từ social-dev', 'Không xóa module tương lai; phần chưa dùng cho giữa kỳ được chuyển thành “đang phát triển”.');
  img(s, 'scope_comparison.png', 0.7, 1.4, 5.65, 4.8);
  const rows = [
    ['Nhóm', 'Giữa kỳ', 'Cách trình bày'],
    ['MVP chính', 'Feed, post, comment, profile, explore, chat cơ bản, projects/jobs, leaderboard', 'Trình bày là đã implement/luồng local.'],
    ['Basic demo', 'Login, register, settings, notifications basic', 'Trình bày mức demo/local, không claim backend auth.'],
    ['Tương lai', 'Analytics, mentorship, playground, live code, AI, recommendation', 'Giữ UI social-dev, gắn nhãn đang phát triển.'],
  ];
  addTableLike(s, rows, 6.65, 1.55, 5.95, 1.07);
  footer(s, 5);
}

function slide6() { sectionSlide(6, 'Thiết Kế Hệ Thống', 'Kiến trúc phân lớp, SQLite-first và đường nâng cấp backend sau midterm.', C.blue); }

function slide7() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Kiến trúc', 'Flutter UI → Repository → SQLite / API', 'UI không gọi SQL hoặc API trực tiếp, để sau này đổi local datasource sang remote datasource dễ hơn.');
  img(s, 'architecture_layers.png', 0.75, 1.35, 5.75, 4.7);
  bulletList(s, [
    'Flutter screens và shared widgets giữ phần trình bày.',
    'Repository gom logic đọc/ghi theo module.',
    'SQLite local lưu dữ liệu runtime chính của Flutter app trong phase giữa kỳ.',
    'Seed data có chọn lọc để bootstrap demo.',
    'Backend prototype Node.js + SQLite server-side đã có thể chạy riêng.',
    'Lớp chuyển đổi tương lai: Flutter repository sẽ nối sang API/backend sau ranh giới repository.',
  ], 7.05, 1.85, 5.1, 3.5);
  footer(s, 7);
}

function slide8() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Database design', 'Thiết kế dữ liệu local', 'SQLite đáp ứng yêu cầu local/remote database trong PRM393 và phù hợp MVP mobile.');
  img(s, 'data_strategy.png', 6.9, 1.25, 5.45, 4.55);
  const rows = [
    ['Bảng', 'Vai trò', 'Ghi chú'],
    ['users/posts/comments', 'Feed, profile, comment', 'Dữ liệu core demo.'],
    ['conversations/messages', 'Chat basic', 'Gửi tin nhắn local.'],
    ['projects/jobs', 'Marketplace & job board', 'Browse có seed chọn lọc.'],
    ['notifications', 'Thông báo', 'Basic read/empty state.'],
  ];
  addTableLike(s, rows, 0.75, 1.55, 5.8, 0.93);
  footer(s, 8);
}

function slide9() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Công nghệ', 'Stack hiện tại và stack phát triển sau', 'Backend prototype đã có, nhưng Docker vẫn để dành cho backend services phức tạp hơn sau này.');
  const items = [
    ['Flutter / Dart', 'UI mobile, routing, Material 3'],
    ['SQLite / sqflite', 'Local database cho demo CRUD'],
    ['Repository pattern', 'Tách UI khỏi data access'],
    ['flutter_test', 'Unit test và widget test nền tảng'],
    ['Puppeteer / pptxgenjs', 'Tự động sinh PDF/PPTX'],
    ['Backend prototype', 'Node.js + SQLite server-side API'],
    ['Docker sau này', 'PostgreSQL, Redis, realtime, AI'],
  ];
  items.forEach((item, i) => {
    const x = i % 2 === 0 ? 0.8 : 6.9;
    const y = 1.55 + Math.floor(i / 2) * 1.35;
    card(s, x, y, 5.55, 1.02);
    pill(s, item[0], x + 0.25, y + 0.2, [C.blue, C.mint, C.violet, C.amber, C.rose, C.ink, C.cyan][i], 1.95);
    s.addText(item[1], { x: x + 2.35, y: y + 0.28, w: 2.85, h: 0.3, fontSize: 10.4, color: C.ink2, margin: 0, fit: 'shrink' });
  });
  footer(s, 9);
}

function slide10() { sectionSlide(10, 'Demo Chức Năng', 'MVP chính chạy trong giữa kỳ, phạm vi đầy đủ được giữ lại dưới dạng đang phát triển.', C.mint); }

function slide11() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Luồng chính 1', 'Nội dung và tương tác', 'Đây là nhóm chức năng nên demo trước vì có luồng dữ liệu rõ nhất.');
  screenshot(s, '04_home_feed.png', 0.75, 1.45, 2.55, 4.65, 'Feed', 'MVP');
  screenshot(s, '08_create_post.png', 3.75, 1.45, 2.55, 4.65, 'Tạo bài viết', 'CRUD');
  screenshot(s, '05_post_detail.png', 6.75, 1.45, 2.55, 4.65, 'Chi tiết & bình luận', 'CRUD');
  screenshot(s, '06_explore.png', 9.75, 1.45, 2.55, 4.65, 'Khám phá', 'MVP');
  footer(s, 11);
}

function slide12() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Luồng chính 2', 'Cộng đồng và cơ hội', 'Nhóm màn hình mở rộng giúp app không chỉ là feed mà là hệ sinh thái developer.');
  screenshot(s, '07_profile.png', 0.75, 1.45, 2.55, 4.65, 'Hồ sơ', 'MVP');
  screenshot(s, '10_chat_list.png', 3.75, 1.45, 2.55, 4.65, 'Danh sách chat', 'MVP');
  screenshot(s, '09_direct_message.png', 6.75, 1.45, 2.55, 4.65, 'Gửi tin nhắn', 'CRUD');
  screenshot(s, '11_notifications.png', 9.75, 1.45, 2.55, 4.65, 'Thông báo', 'BASIC');
  footer(s, 12);
}

function slide13() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Luồng chính 3', 'Dự án, việc làm, bảng xếp hạng', 'Các module browse thể hiện tình huống tìm cơ hội và kết nối cộng đồng.');
  screenshot(s, '12_project_marketplace.png', 0.95, 1.45, 3.05, 4.65, 'Sàn dự án', 'MVP');
  screenshot(s, '13_job_board.png', 5.15, 1.45, 3.05, 4.65, 'Việc làm', 'MVP');
  screenshot(s, '14_leaderboard.png', 9.35, 1.45, 3.05, 4.65, 'Bảng xếp hạng', 'MVP');
  footer(s, 13);
}

function slide14() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Luồng tương lai', 'Màn đang phát triển', 'Đây là phần giữ lại từ social-dev để biết lộ trình refactor sau midterm.');
  screenshot(s, '15_analytics.png', 0.75, 1.45, 2.55, 4.65, 'Analytics', 'PHASE 2');
  screenshot(s, '16_code_playground.png', 3.75, 1.45, 2.55, 4.65, 'Playground', 'PHASE 2');
  screenshot(s, '17_mentorship.png', 6.75, 1.45, 2.55, 4.65, 'Mentorship', 'PHASE 2');
  screenshot(s, '18_live_code.png', 9.75, 1.45, 2.55, 4.65, 'Live Code', 'PHASE 2');
  footer(s, 14);
}

function slide15() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Luồng trạng thái/dữ liệu', 'Kịch bản demo CRUD', 'Chỗ nào cần seed thì seed; còn lại phải test thao tác trong app để chứng minh ghi dữ liệu thật.');
  const flow = [
    ['1', 'Mở feed', 'Dữ liệu seed từ SQLite'],
    ['2', 'Tạo bài viết', 'Insert vào posts'],
    ['3', 'Mở post detail', 'Đọc post + comments'],
    ['4', 'Thêm bình luận', 'Insert vào comments'],
    ['5', 'Gửi tin nhắn', 'Insert vào messages'],
  ];
  flow.forEach((f, i) => {
    const x = 0.8 + i * 2.5;
    card(s, x, 2.0, 2.05, 2.45);
    s.addText(f[0], { x: x + 0.64, y: 2.22, w: 0.75, h: 0.5, fontSize: 24, bold: true, color: [C.blue, C.mint, C.violet, C.amber, C.rose][i], align: 'center', margin: 0 });
    s.addText(f[1], { x: x + 0.22, y: 3.02, w: 1.6, h: 0.32, fontSize: 12.5, bold: true, color: C.ink, align: 'center', margin: 0, fit: 'shrink' });
    s.addText(f[2], { x: x + 0.18, y: 3.58, w: 1.7, h: 0.45, fontSize: 9.2, color: C.muted, align: 'center', margin: 0, fit: 'shrink' });
    if (i < flow.length - 1) {
      s.addText('→', { x: x + 2.1, y: 2.93, w: 0.35, h: 0.3, fontSize: 18, bold: true, color: C.muted, margin: 0 });
    }
  });
  s.addText('Thông điệp khi demo: module tương lai chỉ mở để giải thích lộ trình, không dùng để chứng minh CRUD giữa kỳ.', {
    x: 1.35, y: 5.65, w: 10.7, h: 0.4,
    fontSize: 13, bold: true, color: C.violet,
    align: 'center', margin: 0,
  });
  footer(s, 15);
}

function slide16() { sectionSlide(16, 'Kiểm Thử, Bản Phát Hành, Lộ Trình', 'Bám tiêu chí PRM393: kiểm thử, yêu cầu triển khai, kết luận và đóng góp.', C.amber); }

function slide17() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Yêu cầu kiểm thử', 'Unit test + widget test', 'Đáp ứng mức nền tảng theo đề bài; sau midterm sẽ mở rộng độ phủ kiểm thử cho CRUD chính.');
  metricCard(s, 0.85, 1.75, 'Unit test', '1+', 'Ánh xạ UserRepository', C.blue);
  metricCard(s, 4.2, 1.75, 'Widget test', '1+', 'Hiển thị màn login', C.mint);
  metricCard(s, 7.55, 1.75, 'APK phát hành', 'Đã build', 'app-release.apk khoảng 22.4MB', C.amber);
  img(s, 'testing_quality.png', 1.05, 3.35, 5.4, 2.8);
  bulletList(s, [
    'Chạy `flutter test` trước khi demo.',
    'Test thủ công tạo bài viết, thêm bình luận và gửi tin nhắn.',
    'APK bản phát hành đã build thành công; nếu cần nộp minh chứng ảnh thì chụp lại terminal/app.',
  ], 7.05, 3.65, 4.9, 2.0);
  footer(s, 17);
}

function slide18() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Roadmap refactor', 'Từ midterm lên full social-dev', 'Nhờ giữ full UI/scope, sau giữa kỳ nhóm biết module nào cần refactor và nâng cấp.');
  img(s, 'roadmap_timeline.png', 0.75, 1.35, 6.15, 4.55);
  bulletList(s, [
    'Phase 1: hoàn thành MVP Flutter + SQLite + report/PPTX.',
    'Phase 2: củng cố quản lý trạng thái, interface repository và độ phủ kiểm thử.',
    'Phase 3: nối Flutter sang backend API, rồi thêm Docker Compose, PostgreSQL/Redis nếu cần.',
    'Phase 4: realtime chat/live code, analytics thật, mentorship matching, recommendation/AI.',
  ], 7.25, 1.75, 4.8, 3.5);
  footer(s, 18);
}

function slide19() {
  const s = pptx.addSlide();
  addBg(s);
  addTitle(s, 'Phân công 4 người', 'Gợi ý chia lời thuyết trình', 'Có thể thay tên thật của từng thành viên trước khi nộp.');
  const rows = [
    ['Người 1', 'Slide 1-5', 'Giới thiệu nhóm, tình huống, giải pháp, phạm vi và thông điệp social-dev.'],
    ['Người 2', 'Slide 6-9', 'Kiến trúc, thiết kế dữ liệu, công nghệ sử dụng và hướng chuyển backend.'],
    ['Người 3', 'Slide 10-15', 'Demo chức năng chính và module tương lai đang phát triển.'],
    ['Người 4', 'Slide 16-20', 'Kiểm thử, checklist bản phát hành, lộ trình, đóng góp, kết luận/Q&A.'],
  ];
  rows.forEach((r, i) => {
    const y = 1.55 + i * 1.18;
    card(s, 0.85, y, 11.7, 0.92);
    pill(s, r[0], 1.1, y + 0.27, [C.blue, C.mint, C.violet, C.amber][i], 1.1);
    s.addText(r[1], { x: 2.55, y: y + 0.27, w: 1.4, h: 0.22, fontSize: 10.5, bold: true, color: C.ink, margin: 0 });
    s.addText(r[2], { x: 4.2, y: y + 0.22, w: 7.55, h: 0.35, fontSize: 10.5, color: C.ink2, margin: 0, fit: 'shrink' });
  });
  s.addText('Lưu ý: khi demo các màn tương lai, dùng đúng cụm “đang phát triển cho phase sau”, không nói là đã có backend/realtime/AI thật.', {
    x: 1.1, y: 6.35, w: 11.1, h: 0.34,
    fontSize: 12, bold: true, color: C.rose,
    align: 'center', margin: 0,
  });
  footer(s, 19);
}

function slide20() {
  const s = pptx.addSlide();
  addBg(s, 'dark');
  img(s, 'hero_devconnect.png', 0, 0, W, H);
  s.addShape(pptx.ShapeType.rect, { x: 0, y: 0, w: W, h: H, fill: { color: C.navy, transparency: 10 }, line: { transparency: 100 } });
  s.addText('Kết luận', {
    x: 1.0, y: 1.05, w: 11.3, h: 0.6,
    fontSize: 38, bold: true, color: C.white,
    align: 'center', margin: 0,
  });
  s.addText('DevConnect Mobile đạt mục tiêu giữa kỳ: app Flutter có UI đầy đủ, SQLite local data layer, backend API prototype, kiểm thử nền tảng và lộ trình rõ để tiếp tục phát triển lên phạm vi đầy đủ của social-dev.', {
    x: 1.65, y: 2.05, w: 10.0, h: 0.82,
    fontSize: 17, color: 'E2E8F0',
    align: 'center', margin: 0, fit: 'shrink',
  });
  s.addText('Q&A', {
    x: 4.35, y: 3.45, w: 4.65, h: 0.75,
    fontSize: 46, bold: true, color: C.white,
    align: 'center', margin: 0,
  });
  s.addText('Câu hỏi chuẩn bị: Vì sao chọn SQLite? Module nào là tương lai? Khi nào dùng Docker? Sau midterm refactor gì trước?', {
    x: 1.35, y: 5.05, w: 10.65, h: 0.42,
    fontSize: 12.5, color: 'CBD5E1',
    align: 'center', margin: 0,
  });
  footer(s, 20, true);
}

[
  slide1, slide2, slide3, slide4, slide5,
  slide6, slide7, slide8, slide9, slide10,
  slide11, slide12, slide13, slide14, slide15,
  slide16, slide17, slide18, slide19, slide20,
].forEach((fn) => fn());

(async () => {
  await pptx.writeFile({ fileName: OUT });
  console.log(`Generated ${OUT}`);
})();
