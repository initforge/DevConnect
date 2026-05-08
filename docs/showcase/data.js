// DevConnect Showcase — Dữ liệu màn hình & tính năng

const SCREENS = [
  {
    id: 1, slug: '01_login', title: 'Đăng nhập',
    category: 'auth',
    description: 'Đăng nhập bằng email hoặc tài khoản GitHub. Giao diện trong suốt (glassmorphism) trên nền gradient.',
    features: ['B1', 'A2', 'A6'],
    patterns: ['Kính mờ (Glassmorphism)', 'Nền gradient lưới', 'Hiệu ứng phóng to Spring']
  },
  {
    id: 2, slug: '02_register', title: 'Đăng ký',
    category: 'auth',
    description: 'Form đăng ký 3 bước: thông tin → mật khẩu → xác nhận. Thanh hiển thị độ mạnh mật khẩu, kiểm tra lỗi ngay khi gõ.',
    features: ['B1', 'A2'],
    patterns: ['Form nhiều bước', 'Thanh tiến trình', 'Hiệu ứng trường xuất hiện lần lượt']
  },
  {
    id: 3, slug: '03_onboarding', title: 'Chọn sở thích',
    category: 'auth',
    description: 'Chọn ngôn ngữ lập trình, framework, chủ đề quan tâm. Hệ thống dùng thông tin này để gợi ý bài viết phù hợp.',
    features: ['B10', 'B12'],
    patterns: ['Carousel cuộn nhanh', 'Lưới chip chọn', 'Hiệu ứng nảy khi chọn']
  },
  {
    id: 4, slug: '04_home_feed', title: 'Trang chủ',
    category: 'social',
    description: 'Feed bài viết cá nhân hóa với 3 tab: "Dành cho bạn" (AI gợi ý), "Đang theo dõi", "Xu hướng". Cuộn vô hạn.',
    features: ['B2', 'A1', 'A3', 'A5', 'B10'],
    patterns: ['Tab phân đoạn', 'Thanh điều hướng nổi', 'Bài hiện lần lượt', 'Kéo làm mới']
  },
  {
    id: 5, slug: '05_post_detail', title: 'Chi tiết bài viết',
    category: 'social',
    description: 'Xem bài viết dạng Markdown với code block tô màu. AI có thể đánh giá và giải thích code ngay trong bài.',
    features: ['B3', 'B6', 'B13', 'B14', 'A4'],
    patterns: ['Ảnh cuộn parallax', 'Header thu gọn', 'Bảng thao tác dính đáy', 'Thanh tương tác cố định']
  },
  {
    id: 6, slug: '06_explore', title: 'Khám phá',
    category: 'social',
    description: 'Trang khám phá với lưới bento: bài AI gợi ý, tag xu hướng, lập trình viên nổi bật, chủ đề phổ biến.',
    features: ['B7', 'B10', 'A3'],
    patterns: ['Lưới bento', 'Thanh tìm kiếm mờ', 'Carousel nhìn trước', 'Lưới hiện dần']
  },
  {
    id: 7, slug: '07_profile', title: 'Hồ sơ cá nhân',
    category: 'social',
    description: 'Trang cá nhân với ảnh bìa parallax, biểu đồ đóng góp GitHub, tab Posts/Repos/About.',
    features: ['B4', 'B5', 'C6', 'C7'],
    patterns: ['Header co giãn parallax', 'Avatar thu nhỏ khi cuộn', 'Số đếm chạy', 'Tab phân đoạn']
  },
  {
    id: 8, slug: '08_create_post', title: 'Viết bài',
    category: 'social',
    description: 'Trình soạn thảo Markdown mạnh mẽ, chèn code block, chọn loại bài, bật AI tự động đánh giá code.',
    features: ['B3', 'B11', 'B13'],
    patterns: ['Trình soạn thảo giàu tính năng', 'Thanh công cụ dính đáy', 'Tag nảy vào']
  },
  {
    id: 9, slug: '09_direct_message', title: 'Nhắn tin',
    category: 'communication',
    description: 'Chat 1-1 với code block inline, reactions, chỉ báo đang gõ, trả lời theo thread.',
    features: ['B9', 'A6', 'A5'],
    patterns: ['Bong bóng chat có code', 'Tin nhắn bay vào', 'Dấu chấm đang gõ']
  },
  {
    id: 10, slug: '10_chat_list', title: 'Danh sách chat',
    category: 'communication',
    description: 'Danh sách hội thoại, hàng bạn online, vuốt để lưu trữ/xóa cuộc trò chuyện.',
    features: ['B9', 'A6'],
    patterns: ['Avatar online nhấp nháy', 'Vuốt hiện thao tác', 'Danh sách hiện dần']
  },
  {
    id: 11, slug: '11_notifications', title: 'Thông báo',
    category: 'communication',
    description: 'Thông báo nhóm theo loại. Nhiều thông báo giống nhau → tự gộp. Lọc: Tất cả/Nhắc tên/Theo dõi.',
    features: ['B8', 'A6', 'A3'],
    patterns: ['Danh sách nhóm', 'Chấm chưa đọc nhấp nháy', 'Vuốt để xóa']
  },
  {
    id: 12, slug: '12_project_marketplace', title: 'Sàn dự án',
    category: 'features',
    description: 'Tìm dự án theo công nghệ, trạng thái. Badge tech stack, avatar thành viên, nút "Tham gia".',
    features: ['C4', 'B7', 'A1'],
    patterns: ['Lưới bento', 'Chip lọc nảy', 'Hệ thống badge trạng thái']
  },
  {
    id: 13, slug: '13_job_board', title: 'Bảng tuyển dụng',
    category: 'features',
    description: 'Danh sách việc làm, lọc remote, khoảng lương, tech stack. AI tính % phù hợp kỹ năng.',
    features: ['C8', 'B7', 'B15'],
    patterns: ['Thanh lọc cố định', 'Thẻ hiện lần lượt', 'Thanh trượt lương']
  },
  {
    id: 14, slug: '14_leaderboard', title: 'Bảng xếp hạng',
    category: 'features',
    description: 'Top 3 bục vinh danh, danh sách xếp hạng, thanh XP, mũi tên tăng/giảm hạng.',
    features: ['C6', 'A3'],
    patterns: ['Bục vinh danh nảy vào', 'Thanh XP hiện dần', 'Số đếm chạy']
  },
  {
    id: 15, slug: '15_analytics', title: 'Thống kê & Phân tích',
    category: 'features',
    description: 'Lưới thống kê dạng bento: biểu đồ đường/cột/tròn, bài viết nổi bật, thông tin độc giả.',
    features: ['C7', 'A3'],
    patterns: ['Lưới bento thống kê', 'Biểu đồ vẽ dần', 'Số đếm chạy', 'Sparkline động']
  },
  {
    id: 16, slug: '16_code_playground', title: 'Sân chơi code',
    category: 'tools',
    description: 'Viết và chạy code trực tiếp: chia đôi màn hình soạn thảo/kết quả. Chọn ngôn ngữ, bấm chạy.',
    features: ['C3', 'B13', 'B14'],
    patterns: ['Chia đôi màn hình', 'Kết quả hiện dần', 'Con trỏ nhấp nháy', 'Nút chạy phát sáng']
  },
  {
    id: 17, slug: '17_mentorship', title: 'Ghép cặp mentor',
    category: 'tools',
    description: 'AI tính điểm tương thích kỹ năng (vòng tròn %), danh sách mentor, duyệt theo chuyên môn.',
    features: ['C5', 'B15'],
    patterns: ['Vòng tròn % tự đổ đầy', 'Carousel nhìn trước', 'Số % đếm chạy']
  },
  {
    id: 18, slug: '18_live_code', title: 'Code trực tiếp',
    category: 'tools',
    description: 'Phòng code chung: nhiều người cùng xem code thời gian thực, chat bên cạnh, badge LIVE.',
    features: ['C2', 'A6'],
    patterns: ['Nhiều con trỏ cùng lúc', 'Badge LIVE nhấp nháy', 'Tin nhắn bay vào']
  },
  {
    id: 19, slug: '19_settings', title: 'Cài đặt',
    category: 'tools',
    description: 'Cài đặt theo nhóm: tài khoản, quyền riêng tư, thông báo, giao diện, liên kết GitHub.',
    features: ['B12', 'B1', 'B4'],
    patterns: ['Nhóm mở/đóng', 'Công tắc trượt', 'Chuyển đổi giao diện mượt']
  },
  {
    id: 20, slug: '20_search_results', title: 'Kết quả tìm kiếm',
    category: 'tools',
    description: 'Kết quả phân loại: Bài viết/Người dùng/Dự án. Từ khóa tô sáng, tab lọc.',
    features: ['B7', 'A1'],
    patterns: ['Kết quả phân loại', 'Từ khóa phát sáng', 'Kết quả hiện lần lượt']
  }
];

const FEATURES = {
  // Phần A — Nguyên tắc xuyên suốt
  'A1': { code: 'A.1', title: 'Phân trang thông minh (Cursor)', category: 'data', color: '#F59E0B',
    summary: 'Không tải hết dữ liệu — chỉ lấy 20 mục mỗi lần, cuộn xuống → tự tải thêm. Dùng "con trỏ" (cursor) thay vì số trang.',
    details: 'API: GET /api/posts?cursor=2026-03-10T12:00:00Z&limit=20. Backend lấy 21 dòng, hiển thị 20, dòng thứ 21 dùng để xác định còn tiếp hay không. Flutter: ScrollController lắng nghe khi cuộn > 80% → gọi loadMore() → ghép thêm vào danh sách.',
    difficulty: 2, time: 'Áp dụng xuyên suốt'
  },
  'A2': { code: 'A.2', title: 'Giới hạn tốc độ truy cập', category: 'security', color: '#EF4444',
    summary: 'Chống spam và tấn công — mỗi IP chỉ được gửi tối đa 100 yêu cầu/phút. Đăng nhập sai: tối đa 5 lần/phút.',
    details: 'NestJS @Throttle() decorator. Tầng 1: Global 100 requests/phút/IP. Tầng 2: login 5/phút (chống brute force), posts 10/phút, upload 5/phút. Đếm bằng Redis INCR + EXPIRE. Vượt giới hạn → HTTP 429 + Retry-After header.',
    difficulty: 2, time: 'Áp dụng xuyên suốt'
  },
  'A3': { code: 'A.3', title: 'Bộ nhớ đệm Redis', category: 'data', color: '#F59E0B',
    summary: 'Dữ liệu hay truy cập được lưu tạm trong Redis (bộ nhớ siêu nhanh). Lần sau → trả ngay, không cần hỏi database.',
    details: 'Key patterns: feed:user:123 (hết hạn 5 phút), profile:user:123 (10 phút), post:456 (15 phút), trending:posts (15 phút), online:user:123 (60 giây). Khi dữ liệu thay đổi → xóa cache cũ, lần truy cập sau → tạo cache mới.',
    difficulty: 2, time: 'Áp dụng xuyên suốt'
  },
  'A4': { code: 'A.4', title: 'Xử lý ảnh thông minh', category: 'data', color: '#F59E0B',
    summary: 'Ảnh upload → tự nén + tạo 2 phiên bản: thu nhỏ (xem nhanh) + gốc (xem chi tiết). Lưu thư mục trên VPS.',
    details: 'Client nén ảnh (tối đa 1200px, < 2MB) → POST /media/upload → Server tạo thumb 300px bằng Sharp → Lưu cả 2 vào /uploads/posts/{userId}/ trên VPS → Nginx phục vụ file tĩnh → Trả {thumbnailUrl, fullUrl}. Flutter: cached_network_image + hiệu ứng shimmer khi chờ.',
    difficulty: 3, time: '2-3 ngày'
  },
  'A5': { code: 'A.5', title: 'Giao diện phản hồi tức thì', category: 'ui', color: '#8B5CF6',
    summary: 'Bấm "Thích" hay "Theo dõi" → giao diện thay đổi NGAY LẬP TỨC, không đợi máy chủ. Lỗi? → tự hoàn tác.',
    details: 'Áp dụng: Like, Follow, Bookmark, Vote, Gửi tin nhắn. KHÔNG áp dụng: Tạo bài viết, Xóa (cần xác nhận), Thanh toán. Pattern: cập nhật giao diện ngay → try gọi API → catch → hoàn tác giao diện.',
    difficulty: 2, time: 'Áp dụng xuyên suốt'
  },
  'A6': { code: 'A.6', title: 'Kết nối thời gian thực (WebSocket)', category: 'realtime', color: '#10B981',
    summary: 'Kênh mở liên tục — tin nhắn, thông báo, trạng thái online cập nhật tức thì, không cần tải lại trang.',
    details: 'NestJS Gateway + socket.io. Sự kiện: notification:new, chat:message, chat:typing, user:online, post:new_comment. Mất kết nối → tự kết nối lại (1s → 2s → 4s → tối đa 30s). Khi kết nối lại → đồng bộ tin nhắn đã lỡ.',
    difficulty: 3, time: 'Áp dụng xuyên suốt'
  },

  // Phần B — Tính năng cốt lõi
  'B1': { code: 'B.1', title: 'Đăng nhập & Đăng ký', category: 'security', color: '#EF4444',
    summary: 'Đăng ký bằng email hoặc GitHub. Mã xác thực JWT tự làm mới — người dùng không bao giờ bị đăng xuất bất ngờ.',
    details: 'Email: kiểm tra → mã hóa mật khẩu (bcrypt 12 vòng) → lưu DB → tạo JWT. GitHub OAuth: mở trình duyệt → xác thực → lấy code → đổi token → lấy thông tin → tạo/đăng nhập user → JWT. Token: access (15 phút) + refresh (7 ngày), tự làm mới khi hết hạn.',
    difficulty: 3, time: '3-4 ngày'
  },
  'B2': { code: 'B.2', title: 'Trang chủ Feed cá nhân hóa', category: 'feed', color: '#3B82F6',
    summary: 'Tab "Đang theo dõi" (bài từ người đã follow), "Dành cho bạn" (AI gợi ý), "Xu hướng" (bài nhiều tương tác).',
    details: 'Following: truy vấn bài viết từ người đã follow. For You: Redis cache → miss? → SVD(0.6) + TagMatch(0.3) + Recency(0.1) → lọc bài đã xem → top 50 → cache 5 phút. Trending: điểm = views×0.1 + likes×2 + comments×3 + bookmarks×4, nhân hệ số giảm dần theo thời gian. BullMQ tính lại mỗi 15 phút.',
    difficulty: 4, time: '4-5 ngày'
  },
  'B3': { code: 'B.3', title: 'Viết, sửa, xóa bài (Markdown)', category: 'feed', color: '#3B82F6',
    summary: '6 loại bài: Article, Snippet, TIL, Question, Project, Discussion. Viết bằng Markdown, code block tô màu.',
    details: 'Tạo: kiểm tra → lọc XSS → trích @mention + #hashtag → lưu PostgreSQL → BullMQ thông báo người được nhắc, người theo dõi, xóa cache feed. 6 loại: ARTICLE (dài), SNIPPET (1 đoạn code), TIL (ngắn 500 ký tự), QUESTION (có Best Answer), PROJECT (techStack + GitHub), DISCUSSION. Đếm view: người đọc ở lại ≥ 5 giây mới tính.',
    difficulty: 3, time: '3-4 ngày'
  },
  'B4': { code: 'B.4', title: 'Hồ sơ + Đồng bộ GitHub', category: 'social', color: '#8B5CF6',
    summary: 'Trang cá nhân hiện số bài, follower, following. Đồng bộ repo, ngôn ngữ, đóng góp từ GitHub.',
    details: 'GET /api/users/:username → Redis cache (10 phút) → miss: query user + đếm posts/followers/following + top 5 bài + skills + GitHub. Đồng bộ GitHub: song song GET repos + events → trích top repos, tỉ lệ ngôn ngữ, dữ liệu đóng góp → lưu JSON. Giới hạn: 1 lần đồng bộ/giờ.',
    difficulty: 3, time: '2-3 ngày'
  },
  'B5': { code: 'B.5', title: 'Theo dõi / Bỏ theo dõi', category: 'social', color: '#8B5CF6',
    summary: 'Bấm theo dõi → số đếm cập nhật ngay. Phát hiện "theo dõi lẫn nhau". Feed tự thay đổi.',
    details: 'Follow: INSERT follows → cập nhật atomic follower_count/following_count → thông báo → xóa cache feed. Phát hiện mutual: kiểm tra cả 2 chiều. Danh sách followers: JOIN follows + users, mỗi item kèm isFollowedByMe.',
    difficulty: 2, time: '1-2 ngày'
  },
  'B6': { code: 'B.6', title: 'Bình luận đa cấp (Threading)', category: 'social', color: '#8B5CF6',
    summary: 'Bình luận lồng tối đa 4 cấp. Tải trả lời theo yêu cầu. Vote lên/xuống. Best Answer cho câu hỏi.',
    details: 'Cấu trúc: Comment {parentId, depth 0-3, replyCount đếm sẵn}. Chỉ tải top-level trước, bấm "Xem 5 trả lời" → tải thêm. Depth ≥ 4 → hiện phẳng, thụt tối đa 48px. Tạo bình luận → cập nhật comment_count, reply_count → thông báo tác giả bài viết và bình luận cha.',
    difficulty: 3, time: '3-4 ngày'
  },
  'B7': { code: 'B.7', title: 'Tìm kiếm (Full-Text PostgreSQL)', category: 'data', color: '#F59E0B',
    summary: 'Tìm kiếm tích hợp mọi nơi, dùng PostgreSQL Full-Text Search. Chờ 300ms sau khi gõ mới tìm (debounce).',
    details: 'ALTER TABLE posts ADD COLUMN search_vector tsvector + GIN index. Trigger tự cập nhật khi tạo/sửa bài. Query: WHERE search_vector @@ plainto_tsquery, sắp xếp theo ts_rank. Flutter: SearchBar debounce 300ms, lưu lịch sử tìm kiếm, gợi ý tự động.',
    difficulty: 2, time: '1-2 ngày'
  },
  'B8': { code: 'B.8', title: 'Thông báo (Trong app + Push)', category: 'realtime', color: '#10B981',
    summary: '7 loại thông báo. ≥ 3 thông báo giống nhau trong 5 phút → tự gộp. Offline → gửi push qua điện thoại.',
    details: 'Loại: LIKE, COMMENT, REPLY, FOLLOW, MENTION, BEST_ANSWER, PROJECT. Luồng: sự kiện xảy ra → lưu PostgreSQL → Redis INCR số chưa đọc → WebSocket push (nếu online) → FCM push (nếu offline). Gộp: "UserA, UserB và 5 người khác thích bài viết".',
    difficulty: 3, time: '3-4 ngày'
  },
  'B9': { code: 'B.9', title: 'Chat trực tiếp (MongoDB + WebSocket)', category: 'realtime', color: '#10B981',
    summary: 'Chat MongoDB (linh hoạt), WebSocket (thời gian thực). Gửi text, ảnh, code. Chỉ báo đang gõ.',
    details: 'MongoDB: conversations {participants, lastMessage, unreadCount} + messages {type: text|image|code, reactions, readBy, status}. Gửi tin: UI hiện ngay → WebSocket emit → server lưu + cập nhật → broadcast người nhận → nếu offline → FCM push. Đang gõ: debounce 2 giây, tự ẩn sau 5 giây.',
    difficulty: 4, time: '5-7 ngày'
  },
  'B10': { code: 'B.10', title: 'Gợi ý thông minh (SVD)', category: 'ai', color: '#00D9A6',
    summary: 'Phân tích hành vi người dùng (xem, thích, lưu) → tìm bài viết phù hợp nhất. Kết hợp AI + nội dung + bạn bè.',
    details: 'Ma trận tương tác: SKIP(-1), VIEW(1), LIKE(3), COMMENT(4), BOOKMARK(5). scipy.sparse.linalg.svds k=20. Điểm cuối = SVD(50%) + Nội dung trùng tag(30%) + Mới(10%) + Bạn bè(10%). User mới (< 50 tương tác): dùng sở thích từ onboarding. BullMQ tính lại mỗi 6 giờ, 500 users × 1000 posts: < 1 giây.',
    difficulty: 4, time: '4-5 ngày'
  },
  'B11': { code: 'B.11', title: 'Upload ảnh/media', category: 'data', color: '#F59E0B',
    summary: 'Client nén + giảm kích thước → upload → server tạo ảnh thu nhỏ → lưu trên VPS theo thư mục.',
    details: 'Client: kiểm tra loại file (jpg/png/gif/webp), tối đa 5MB, nén + resize 1200px. Server: FileValidationPipe → Sharp tạo thumb 300px → lưu vào /uploads/{type}/{userId}/ trên VPS → Nginx phục vụ → trả {mediaId, thumbnailUrl, fullUrl}. Thanh tiến trình: Dio onSendProgress. Dọn dẹp ảnh lẻ hàng tuần.',
    difficulty: 3, time: '2-3 ngày'
  },
  'B12': { code: 'B.12', title: 'Cài đặt ứng dụng', category: 'ui', color: '#8B5CF6',
    summary: 'Tài khoản, Quyền riêng tư, Thông báo, Giao diện. Lưu vừa trên server vừa trên máy.',
    details: 'Nhóm: Tài khoản (sửa hồ sơ, đổi mật khẩu, liên kết GitHub, xóa tài khoản 30 ngày hoàn tác), Quyền riêng tư (hiển thị hồ sơ, online, ai nhắn tin), Thông báo (bật/tắt theo loại, giờ yên tĩnh 22h-8h), Giao diện (tối/sáng, cỡ chữ, ngôn ngữ). Backend: GET/PATCH /api/users/me/settings.',
    difficulty: 2, time: '1-2 ngày'
  },
  'B13': { code: 'B.13', title: 'AI Đánh giá code', category: 'ai', color: '#00D9A6',
    summary: 'Gửi code → Proxy AI open-source phân tích lỗi, hiệu năng, bảo mật, code sạch → chấm điểm 1-10.',
    details: 'Dùng tại: Sân chơi code, Chi tiết bài viết, Viết bài. POST /api/ai/code-review {code, language}. Giới hạn: 20 lần/ngày/user. Proxy AI phân tích → trả {score, issues: [{type, severity, line, message, fix}], summary}. Cache Redis 24h → cùng code → trả ngay, không gọi API.',
    difficulty: 3, time: '2-3 ngày'
  },
  'B14': { code: 'B.14', title: 'AI Giải thích code', category: 'ai', color: '#00D9A6',
    summary: '3 cấp độ: Người mới (giải thích đơn giản), Trung cấp (patterns, lý do), Nâng cao (phức tạp, đánh đổi).',
    details: 'POST /api/ai/explain {code, language, level}. Prompt theo cấp: Beginner "giải thích như sinh viên năm 1", Intermediate "patterns, quyết định thiết kế", Advanced "phức tạp O(), đánh đổi, giải pháp thay thế". Trả: {explanation (markdown), concepts[], complexity, alternatives}. Cache 24h.',
    difficulty: 2, time: '1-2 ngày'
  },
  'B15': { code: 'B.15', title: 'AI Ghép cặp Mentor', category: 'ai', color: '#00D9A6',
    summary: 'Tính điểm tương thích: kỹ năng trùng(40%) + khoảng cách kinh nghiệm(20%) + lịch phù hợp(20%) + đánh giá(20%).',
    details: 'Input: kỹ năng mentee, mục tiêu, kinh nghiệm, lịch. Chấm điểm mỗi mentor: skill_overlap / goals × 0.4 + experience_gap (tối ưu 3-7 năm) × 0.2 + schedule_match × 0.2 + avgRating/5 × 0.2. AI tùy chọn: Proxy AI đánh giá tương thích bio. Cache 1 giờ.',
    difficulty: 3, time: '3-4 ngày'
  },

  // Phần C — Tính năng mở rộng
  'C2': { code: 'C.2', title: 'Phòng code trực tiếp', category: 'realtime', color: '#10B981',
    summary: 'Phòng code chung — host gõ code, mọi người xem thời gian thực. Như "Google Docs cho code" thu nhỏ.',
    details: 'Tạo phòng: POST /api/live/rooms → roomId. Tham gia: WebSocket connect + join room. Host gõ → emit code:change {delta} → server broadcast → viewers áp dụng delta. Đơn giản hóa: chỉ host chỉnh sửa, viewers xem + chat bên cạnh.',
    difficulty: 4, time: '4-6 ngày'
  },
  'C3': { code: 'C.3', title: 'Sân chơi code (Sandbox)', category: 'tools', color: '#06B6D4',
    summary: 'Viết code + bấm chạy. Hỗ trợ Python, JS, Dart, C++. Chạy an toàn trong môi trường cách ly.',
    details: 'POST /api/playground/run {language, code, stdin}. Dùng Judge0 API (miễn phí 50 lần/ngày). Bảo mật: Docker container không mạng (--network=none), giới hạn RAM 128MB, CPU 0.5, timeout 10 giây. Trả: {stdout, stderr, time, memory}.',
    difficulty: 3, time: '2-4 ngày'
  },
  'C4': { code: 'C.4', title: 'Sàn dự án (Marketplace)', category: 'social', color: '#8B5CF6',
    summary: 'Đăng dự án, tìm thành viên. Lọc theo tech stack, trạng thái. Quy trình: nộp đơn → chủ duyệt.',
    details: 'Model: Project {title, description, githubUrl, techStack[], status, maxMembers}. Duyệt: GET /api/projects?tech=flutter&status=LOOKING. Xin tham gia: POST /api/projects/:id/join {message} → PENDING → chủ Accept/Reject → ACCEPTED: thêm thành viên + thông báo.',
    difficulty: 3, time: '3-4 ngày'
  },
  'C5': { code: 'C.5', title: 'Hệ thống Mentorship', category: 'social', color: '#8B5CF6',
    summary: 'Tìm mentor, gửi yêu cầu, theo dõi tiến trình. AI tóm tắt hàng tuần: "Bạn đã hoàn thành 3/5 mục tiêu".',
    details: 'Hồ sơ mentor: kỹ năng, kinh nghiệm, lịch, đánh giá. Yêu cầu: POST /api/mentorship/requests {mentorId, message, goals} → mentor Accept → ACTIVE. Theo dõi: mentee ghi nhật ký, mentor phản hồi, badge cột mốc ("Tuần 1 hoàn thành", "PR đầu tiên").',
    difficulty: 3, time: '3-4 ngày'
  },
  'C6': { code: 'C.6', title: 'Bảng xếp hạng', category: 'social', color: '#8B5CF6',
    summary: 'Tính điểm từ hoạt động: like +2, bookmark +3, best answer +15. Xếp hạng: ngày/tuần/tháng/mọi thời.',
    details: 'Chấm điểm: Bài được like +2/like, bookmark +3, comment upvoted +1, best answer +15, follower mới +1, đóng góp dự án +5. Truy vấn: SUM(points) GROUP BY user theo thời gian. Cache Redis 15 phút. Tác vụ nền mỗi giờ: tính lại + trao badge "Top 10 tuần này".',
    difficulty: 2, time: '2 ngày'
  },
  'C7': { code: 'C.7', title: 'Thống kê & Phân tích', category: 'data', color: '#F59E0B',
    summary: 'Thống kê cá nhân: lượt xem/thích/bình luận theo thời gian, bài nổi bật, thông tin độc giả.',
    details: 'GET /api/analytics/me?period=30d. Truy vấn tổng hợp: GROUP BY DATE cho views/likes theo ngày. Top 5 bài theo views. Thông tin độc giả: topSkills[], thời gian đọc trung bình. Biểu đồ: fl_chart (đường, cột, tròn). Cache 1 giờ.',
    difficulty: 3, time: '3-4 ngày'
  },
  'C8': { code: 'C.8', title: 'Bảng tuyển dụng', category: 'features', color: '#F59E0B',
    summary: 'Đăng việc + quy trình ứng tuyển. Lọc tech/remote/lương. AI tính % phù hợp kỹ năng.',
    details: 'Model: JobPost {title, description, type, location, remote, salaryRange, techStack[], experience, status, expiresAt}. Ứng tuyển: POST /api/jobs/:id/apply {coverNote, resumeUrl}. AI matching: overlap = INTERSECTION(user.skills, job.techStack) / techStack.length → badge "85% phù hợp".',
    difficulty: 3, time: '3-4 ngày'
  }
};

const CATEGORIES = {
  all:           { label: 'Tất cả',          count: 20 },
  auth:          { label: 'Xác thực',        count: 3  },
  social:        { label: 'Mạng xã hội',     count: 5  },
  communication: { label: 'Giao tiếp',       count: 3  },
  features:      { label: 'Tính năng',       count: 4  },
  tools:         { label: 'Công cụ',         count: 5  }
};

const FEATURE_CATEGORIES = {
  security: { label: 'Bảo mật',       color: '#EF4444' },
  feed:     { label: 'Feed',          color: '#3B82F6' },
  social:   { label: 'Xã hội',        color: '#8B5CF6' },
  data:     { label: 'Dữ liệu',       color: '#F59E0B' },
  realtime: { label: 'Thời gian thực', color: '#10B981' },
  ai:       { label: 'Trí tuệ nhân tạo', color: '#00D9A6' },
  ui:       { label: 'Giao diện',      color: '#8B5CF6' },
  tools:    { label: 'Công cụ',        color: '#06B6D4' },
  features: { label: 'Tính năng',      color: '#F59E0B' }
};

const TECH_STACK = [
  { name: 'Flutter', role: 'Ứng dụng di động' },
  { name: 'NestJS', role: 'Máy chủ API' },
  { name: 'PostgreSQL', role: 'CSDL chính' },
  { name: 'MongoDB', role: 'CSDL chat' },
  { name: 'Redis', role: 'Bộ nhớ đệm' },
  { name: 'VPS Storage', role: 'Lưu trữ file (chia thư mục)' },
  { name: 'Proxy AI open-source', role: 'Đánh giá & Giải thích code' },
  { name: 'Firebase', role: 'Thông báo đẩy' },
  { name: 'Docker', role: 'Đóng gói ứng dụng' },
  { name: 'BullMQ', role: 'Hàng đợi tác vụ' }
];
