# 08 - Showcase Alignment Checklist

> Muc tieu cua tai lieu nay la dua cac man hinh trong app Flutter ve dung visual intent cua `docs/showcase`, dong thoi giu ro ranh gioi giua phan UI dang lam ngay va phan backend/logic de lai sau.
>
> Luu y quan trong: `docs/showcase/screenshots` la stitched design references theo tung man, khong phai source of truth he thong cho bottom nav, app shell, navigation labels, hay CTA conventions. Neu cac anh mau thuan nhau o thanh phan dung chung, runtime phai uu tien 1 quy uoc thong nhat.

---

## 1. Scope hien tai

### Lam ngay

- Can chinh UI, layout, spacing, section hierarchy, card/chip/badge/tab/filter/FAB/toolbars theo showcase.
- Bo sung cac state hien thi can thiet: selected, unread, applied, following, empty, loading, error.
- Canh lai navigation va interaction co ban de flow on dinh khi verify bang anh.
- Bo sung cac man hoac route con thieu neu showcase dang the hien mot man rieng.

### Dinh nghia dung ve showcase

- `docs/showcase/index.html` va `docs/showcase/screenshots/*.png` duoc dung de lay visual direction va composition theo tung man.
- Khong xem bo screenshot nay la mot design system da chot 100% giua cac man.
- Cac thanh phan dung chung theo he thong nhu bottom nav, app shell, title naming, route flow phai duoc chot rieng trong runtime app.

### Deferred theo scope da chot

- GitHub auth that
- Recommendation engine that
- GitHub sync backend that

### Nguyen tac khi gap phan deferred

- UI van phai khop showcase neu co the.
- Khong duoc gia vo la backend da hoan tat.
- Neu can mock/stub state de dat showcase thi phai note ro trong tong ket cuoi.

---

## 2. Tieu chi hoan thanh

Moi man hinh duoc coi la dat khi thoa tat ca dieu kien sau:

1. Khop cau truc man:
   - App bar
   - Section order
   - Tabs / filters
   - CTA chinh
   - Bottom nav / FAB
2. Khop thanh phan hien thi:
   - Chips
   - Badges
   - Avatar stack
   - Stat cards
   - Code blocks
   - Action rows
3. Khop nhip layout:
   - Spacing
   - Grouping
   - Kich thuoc khoi chinh
   - Visual hierarchy
4. Co state chinh:
   - Selected
   - Unread
   - Applied
   - Following
   - Toggle on/off
   - Empty/loading/error khi can
5. Verify bang anh chay that, khong ket luan chi dua vao code.
6. Neu screenshot references mau thuan nhau o thanh phan dung chung, runtime phai theo canonical system da chot, khong copy tung anh mot cach may moc.

---

## 3. Cach thuc lam viec

### Buoc 0 - Chot app shell va navigation architecture

Truoc khi polish sau cung theo tung man, phai chot cac quy uoc he thong sau:

- Chi duoc ton tai 1 he bottom navigation chinh cho app
- Chi duoc ton tai 1 quy uoc CTA tao moi chinh
- Route tab chinh phai di qua cung mot shell
- Label tab, title man, action icon phai dung cung mot tu dien
- Khong de runtime mode va screenshot mode dung 2 navigation pattern khac nhau
- Neu cac screenshot stitch khac nhau o menu/nav/app bar, phai uu tien 1 runtime canon thay vi giu nguyen moi bien the

### Buoc 1 - Chuan hoa primitive UI dung chung

Ra va nang cap cac thanh phan tai su dung:

- `app/lib/core/widgets/shared_widgets.dart`
- `app/lib/core/theme/app_theme.dart`
- `app/lib/core/theme/app_colors.dart`

Primitive du kien can co:

- Segmented tabs
- Filter chips
- Section header
- Stat tiles
- Badge / unread dot
- Card layouts dung cho feed, projects, jobs, notifications
- Composer / toolbar components
- Code preview / code block UI
- App shell scaffold
- App bar variants (title only / title + actions / search header)
- Bottom navigation spec
- FAB / primary create action spec
- Route helpers dung `AppRoutes`

### Buoc 2 - Lam theo cum man

Thu tu uu tien:

1. Auth
2. Feed + Post + Explore + Search
3. Profile + Chat + Notifications + Settings
4. Projects + Jobs + Leaderboard + Analytics
5. Playground + Mentorship + Live Code

### Buoc 3 - Verify theo cum

Sau moi cum:

- Chay app
- Dieu huong den tung man
- Chup anh that
- Doi chieu voi anh showcase tuong ung
- Sua cac lech con lai truoc khi sang cum tiep theo

---

## 4. Checklist theo tung man

## 4.1 Auth

### `01_login`

File:

- `app/lib/features/auth/screens/login_screen.dart`

Can dat:

- Hero gradient + logo treatment sat showcase
- Card dang nhap noi bat
- Email/password field bo tron
- Link forgot password dung vi tri
- CTA `Sign In`
- Nut GitHub dung bo cuc showcase

Luu y:

- GitHub auth that de lai sau
- UI nut GitHub van phai khop showcase

Verify:

- Chup man login
- Kiem tra hero, card, input, CTA, GitHub button, spacing

### `02_register`

File:

- `app/lib/features/auth/screens/register_screen.dart`

Can dat:

- Wizard layout sat showcase
- Progress indicator dung nhip
- Form fields theo tung step
- Password strength treatment
- Terms / Privacy checkbox
- Footer link dang nhap

Verify:

- Chup step 1
- Chup step password
- Kiem tra progress, CTA, field spacing, checkbox, footer

### `03_onboarding`

File:

- `app/lib/features/auth/screens/onboarding_screen.dart`

Can dat:

- Title / subtitle dung hierarchy
- Grid card theo tung skill
- Co icon per item
- Selected badge o goc
- Progress dots
- CTA co dinh duoi

Verify:

- Chup man onboarding
- Kiem tra grid, icon, selected state, CTA

## 4.2 Feed / Post / Explore / Search

### `04_home_feed`

Files:

- `app/lib/features/feed/screens/home_screen.dart`
- `app/lib/features/feed/widgets/post_card.dart`

Can dat:

- Top bar co brand + search + notifications
- Tabs `For You / Following / Trending`
- Feed cards sat layout showcase
- AI-picked treatment neu can
- FAB dung vi tri va style

Verify:

- Chup man feed
- Kiem tra top actions, tabs, card hierarchy, FAB

### `05_post_detail`

File:

- `app/lib/features/feed/screens/post_detail_screen.dart`

Can dat:

- Header co back/share/bookmark
- Author block + follow CTA
- Tags chips
- Markdown/code block card dung treatment
- Action row gan day

Luu y:

- AI explain / AI review that de sau neu dinh toi backend
- UI code block va CTA van phai khop showcase

Verify:

- Chup detail
- Kiem tra header, author block, tag row, code block, action row

### `06_explore`

File:

- `app/lib/features/explore/screens/explore_screen.dart`

Can dat:

- Search bar
- Filter action
- Topic chips
- AI picks section
- Top developers row
- Popular topics cards

Verify:

- Chup explore
- Kiem tra search/filter/chips/cards/quick access

### `08_create_post`

File:

- `app/lib/features/feed/screens/create_post_screen.dart`

Can dat:

- Type segmented pills
- Composer lon
- Code preview card
- Tags row
- AI Code Review toggle
- Toolbar duoi
- Media actions

Verify:

- Chup create post
- Kiem tra type tabs, preview block, tags, AI toggle, toolbar

### `20_search_results`

Files:

- `app/lib/features/explore/screens/explore_screen.dart`
- `app/lib/routing/app_router.dart`
- Co the can tao screen moi neu tach route

Can dat:

- Man rieng cho ket qua tim kiem
- Tabs `All / Posts / People / Projects`
- Recent search chips
- Sections cho posts / people / projects

Verify:

- Chup ket qua tim kiem
- Kiem tra tabs, chips, grouping, bottom nav

## 4.3 Profile / Chat / Notifications / Settings

### `07_profile`

File:

- `app/lib/features/profile/screens/profile_screen.dart`

Can dat:

- Gradient cover composition
- Avatar overlap
- 3 stats
- Follow button
- GitHub connected card
- Tabs `Posts / Projects / About` hoac treatment sat showcase

Luu y:

- GitHub sync that de lai sau
- Card GitHub duoc phep mock state

Verify:

- Chup profile
- Kiem tra cover, stats, CTA, GitHub card, tabs

### `09_direct_message`

File:

- `app/lib/features/chat/screens/chat_screen.dart`

Can dat:

- Header co online status + action icons
- Message bubbles sat showcase
- Code bubble / link preview bubble
- Composer day du

Verify:

- Chup direct message
- Kiem tra header, bubble treatment, preview card, composer

### `10_chat_list`

File:

- `app/lib/features/chat/screens/chat_list_screen.dart`

Can dat:

- Search conversations
- Online strip
- Swipe action
- Unread indicator
- Timestamp treatment

Verify:

- Chup chat list
- Kiem tra search, online row, swipe affordance, unread state

### `11_notifications`

File:

- `app/lib/features/notifications/screens/notifications_screen.dart`

Can dat:

- Filter tabs `All / Mentions / Follows`
- `Mark all as read`
- Group `Today / Earlier`
- Notification cards
- Action rows neu showcase co

Verify:

- Chup notifications
- Kiem tra tabs, grouping, row treatment, CTA chip/button

### `19_settings`

File:

- `app/lib/features/settings/screens/settings_screen.dart`

Can dat:

- Grouped cards by section
- Privacy controls
- Notification toggles
- Quiet hours row
- Theme / font / language rows
- Delete account row
- Logout row

Verify:

- Chup settings
- Kiem tra section cards, toggles, row alignment, destructive row

## 4.4 Projects / Jobs / Leaderboard / Analytics

### `12_project_marketplace`

File:

- `app/lib/features/projects/screens/project_marketplace_screen.dart`

Can dat:

- Filter chips
- Member avatars
- Save / bookmark affordance
- Join CTA
- FAB dung style showcase

Verify:

- Chup projects
- Kiem tra filters, card layout, member avatars, CTA

### `13_job_board`

File:

- `app/lib/features/projects/screens/job_board_screen.dart`

Can dat:

- Summary stats cards
- Remote toggle
- Filter chips
- Match badges
- Apply CTA sat showcase

Verify:

- Chup jobs
- Kiem tra stats, filter, card hierarchy, apply state

### `14_leaderboard`

File:

- `app/lib/features/leaderboard/screens/leaderboard_screen.dart`

Can dat:

- Segmented range filter
- Top 3 podium
- Current user card
- Ranked list
- Up/down movement treatment neu co

Verify:

- Chup leaderboard
- Kiem tra podium, segmented tabs, current-user card, list

### `15_analytics`

File:

- `app/lib/features/analytics/screens/analytics_screen.dart`

Can dat:

- Range segmented tabs
- Summary cards
- Chart card
- Top performing list
- Audience insights

Verify:

- Chup analytics
- Kiem tra summary metrics, chart framing, lists, insight bars

## 4.5 Tools

### `16_code_playground`

File:

- `app/lib/features/playground/screens/playground_screen.dart`

Can dat:

- Language selector
- Settings affordance
- Editor card
- Console output card
- AI Review / AI Explain cards

Verify:

- Chup playground
- Kiem tra editor, output, status, assistance cards

### `17_mentorship`

File:

- `app/lib/features/mentorship/screens/mentorship_screen.dart`

Can dat:

- Hero card `AI Mentor Match`
- CTA `Find My Match`
- Best matches section
- Expertise chips
- Top rated mentors

Luu y:

- Matching engine that de lai sau
- UI va data demo van phai sat showcase

Verify:

- Chup mentorship
- Kiem tra hero, CTA, chips, mentor cards

### `18_live_code`

File:

- `app/lib/features/playground/screens/live_code_screen.dart`

Can dat:

- Day la man live session, khong chi la room list
- Header LIVE + timer + end call
- Editor khung lon
- Cursor labels / viewer avatars treatment
- Bottom action bar
- Mini chat bubble

Verify:

- Chup live code
- Kiem tra session header, editor framing, bottom controls

---

## 5. Quy trinh verify

### Verify he thong truoc verify tung man

Can check rieng nhom sau:

1. Bottom nav
- Co phai chi ton tai 1 implementation?
- Selected state co dung tren moi route chinh?
- Label co dong bo toan app?

2. FAB / CTA tao moi
- Vi tri co nhat quan?
- Icon / label / hanh vi co theo mot quy uoc chung?

3. App bar
- Cung loai man co dung chung title hierarchy va action spacing?
- Search / filter / share / bookmark co treatment dong bo?

4. Route architecture
- Main feature screens co nam trong shell hay dang dung nav gia lap?
- Co con magic string route thay vi route constants khong?

### Verify ky thuat

- Chay app Flutter sau moi dot sua
- Dam bao khong co overflow, layout jumps, text overlap
- Kiem tra route va interaction chinh cua cac man vua sua

### Verify bang anh

Voi moi cum man:

1. Mo man can doi chieu
2. Chup anh that
3. So voi anh showcase tuong ung
4. Danh dau:
   - Khop
   - Lech nhe
   - Thieu section
   - Sai state
   - Mau thuan he thong giua cac screenshot
5. Sua lai cho den khi qua nguong chap nhan

### Nguong pass

- Khong thieu section chinh
- Khong sai loai control
- Khong co overflow hoac clip loi
- Spacing va hierarchy khong lech ro rang
- State selected/unread/toggle duoc the hien dung
- Shared system elements khong bi tach thanh nhieu pattern khac nhau chi vi screenshot stitch khong dong nhat

---

## 6. Tong ket implementation

Khi ket thuc dot nay, can bao cao:

- File da sua
- Man da verify
- Man con rui ro nho neu co
- Danh sach deferred:
  - GitHub auth that
  - Recommendation engine that
  - GitHub sync backend that
