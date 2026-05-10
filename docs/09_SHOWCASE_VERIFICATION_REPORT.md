# 09 - Showcase Verification Report

Ngay verify: 2026-05-09

Nguon doi chieu:
- Showcase mockups: `docs/showcase/screenshots/*.png`
- Anh app thuc te: `output/playwright/audit_mobile_v2/*.png`
- Contact sheet tong hop: `output/playwright/audit_contact_sheet_v2.png`
- Anh doi chieu rieng cho cac man da sua state: `output/playwright/profile_fresh.png`, `output/playwright/chatdetail_fresh.png`
- Ghi chu cach doc: bo screenshot showcase la stitched design references theo tung man, khong phai mot design system da chot 100% cho cac thanh phan dung chung

Phuong phap:
- Build Flutter web voi `SCREENSHOT_MODE=true`
- Bat route access de chup tung man thuc te
- Chup viewport mobile `390 x 844`
- Doi chieu bang anh, khong ket luan chi dua vao code
- Chay smoke test route/screens sau khi sua de xac nhan khong con runtime error

## Cach doc bao cao nay

Bao cao tach 2 lop danh gia:

1. Visual per-screen parity:
 - Tung man co giu duoc visual intent cua screenshot tham chieu hay khong
2. Runtime system parity:
 - App shell, bottom nav, route flow, CTA conventions, va shared patterns co duoc thong nhat thanh 1 he thong rieng hay khong

Vi vay, mot man co the da gan screenshot tham chieu, nhung toan app van chua "dong bo" neu navigation/menu/shared components van phan manh.

## Ket luan nhanh

Trang thai hien tai: **Tien bo ro, da dong blocker route/state, nhung chua runtime-system-ready**

Ly do chinh:
- Neu xem showcase nhu visual target theo tung man, nhieu man da gan hon ro rang.
- Neu xem showcase nhu mot app da he thong hoa hoan chinh, runtime hien tai van chua dat.
- Hai man tung loi state/du lieu that la `07_profile` va `09_direct_message` da render dung lai theo anh verify moi.
- Mot so man khong thieu route nhung UI hien tai khac showcase ro rang.

## Danh gia theo man

| Man | Trang thai | Ghi chu |
|---|---|---|
| `01_login` | Lech nhe | Gan showcase, nhung viewport/layout van rong hon mockup va treatment card/chia doan chua sat 100%. |
| `02_register` | Lech nhe | Cau truc dung huong, nhung nhip layout, progress, field density khac showcase. |
| `03_onboarding` | Lech nhe | Grid va selected state da co, nhung hierarchy va card treatment chua sat. |
| `04_home_feed` | Lech nhe | Card hierarchy da gan hon, nhung bottom nav va feed density van khac showcase. |
| `05_post_detail` | Lech ro rang | Header, author block, code card, action row van khac showcase ro. |
| `06_explore` | Lech nhe | Co dung cac section chinh, nhung visual grouping va card scale khac. |
| `07_profile` | Lech nhe | Da render dung state profile va feed cua user; con lech cover composition, action hierarchy va do chat cua card so voi showcase. |
| `08_create_post` | Lech ro rang | Composer, segmented pills, code preview, toolbar khac showcase. |
| `09_direct_message` | Lech nhe | Da render dung conversation state va message card; con lech bubble treatment, spacing va bottom composer so voi showcase. |
| `10_chat_list` | Lech nhe | Online strip va row treatment da gan hon, con lech bottom nav va avatar/card spacing. |
| `11_notifications` | Lech nhe | Da co tabs/grouping, nhung card treatment va action hierarchy chua sat. |
| `12_project_marketplace` | Lech nhe | Filter chips va card layout da gan hon, con lech visual density va member/footer treatment. |
| `13_job_board` | Lech nhe | Co stats/filter/match/apply, nhung hierarchy va card density khac. |
| `14_leaderboard` | Lech nhe | Da co podium/list, nhung segmented filter va treatment tong the khac. |
| `15_analytics` | Lech nhe | Da co summary/chart/list, nhung khong giong bento analytics showcase. |
| `16_code_playground` | Lech ro rang | Da dung huong tool surface, nhung editor/output composition van khac showcase. |
| `17_mentorship` | Lech nhe | Hero va mentor cards da gan showcase hon, con lech compactness va card rhythm. |
| `18_live_code` | Lech nhe | Da chuyen thanh live session view, con lech ve bottom controls va chat bubble composition. |
| `19_settings` | Lech nhe | Co grouped settings va toggles, nhung bo cuc va density khac showcase. |
| `20_search_results` | Lech nhe | Da co recent searches + tabs + sections, nhung hierarchy va cards chua sat. |

## Cac blocker parity quan trong

1. Cum social core van lech nhieu nhat:
 - `05_post_detail`
 - `08_create_post`
 - `10_chat_list`

2. Cum tools chua sat showcase:
 - `16_code_playground`
 - `18_live_code`
 - Van can them mot vong polish visual nua de sat mockup

3. Cum feature van con lech composition:
 - `12_project_marketplace`
 - `15_analytics`

4. Cac blocker route/state truoc day da duoc dong:
 - `07_profile`
 - `09_direct_message`
 - Smoke test `integration_test/verify_updated_screens_smoke_test.dart` da pass sau khi dong bo label moi cua playground

## Cac blocker he thong / kien truc UI chua dong bo

Day la nhom van de cho thay vi sao khong nen doc bo screenshot stitch nhu source of truth duy nhat. Runtime van phai tu chot 1 canonical system.

Day la nhom van de can xu ly theo he thong, khong nen tiep tuc fix rieng tung man:

1. Dang ton tai 2 he navigation song song:
 - Runtime main tabs dung `ShellRoute` + `NavigationBar` trong `app/lib/routing/app_router.dart`
 - Nhieu man showcase dung `ShowcaseBottomNav` trong `app/lib/core/widgets/shared_widgets.dart`
 - Hai he nay khac nhau ve hinh, label, vi tri CTA va selected state

2. Mot so man feature ngoai shell dang "gia lap" bottom nav trong screenshot mode:
 - `12_project_marketplace`
 - `15_analytics`
 - `16_code_playground`
 - `05_post_detail`
 - Runtime that cua cac man nay khong dung chung app shell nen khong co navigation he thong giong nhau

3. CTA trung tam va FAB chua co mot quy uoc duy nhat:
 - Shell runtime dung `FloatingActionButton` edit o goc
 - `ShowcaseBottomNav` dung nut `+` nam giua
 - Vai man feature lai tu gan FAB rieng
 - Ket qua la cung mot app nhung mau hanh vi tao moi / action chinh bi tach 3 kieu

4. Label navigation va ngon ngu dieu huong chua nhat quan:
 - Bottom tab shell dang dung `Alerts`
 - Screen title va flow noi bo dung `Notifications`
 - Chat screen/list title va tab naming cung khong theo mot tu dien duy nhat

5. Route constants da co nhung chua duoc su dung dong bo:
 - `app/lib/core/constants/routes.dart` da dinh nghia `AppRoutes`
 - Nhieu man van `context.go('/home')`, `context.push('/search')`, `context.push('/user/...')` bang magic string
 - Viec nay lam navigation cleanup ve sau de vo manh va kho refactor

6. Theme navigation chua tap trung:
 - Theme hien co `BottomNavigationBarThemeData`
 - App dang dung `NavigationBar` va custom `ShowcaseBottomNav`
 - Chua co mot `NavigationBarThemeData` / shared nav spec lam nguon su that duy nhat

7. App bar pattern chua co contract chung:
 - Cung loai man nhung title/action/search/filter layout bi viet rieng tung noi
 - Screenshot mode va runtime mode cua cung mot man doi khi dung 2 header pattern khac nhau

## Ket luan bo sung

Neu chi tiep tuc "lam giong tung man" ma khong xu ly nhom blocker tren, thi app se van co cam giac ghep man:
- tung screen co the dep hon
- nhung menu, navigation, CTA, title bar va route flow van khong cung mot he

Vi vay, dot tiep theo nen co mot pha "UI architecture alignment" rieng truoc khi polish sau cung.

Noi cach khac:
- showcase dung de dinh huong visual va composition
- runtime app phai la ban he thong hoa lai cac man do thanh 1 san pham thong nhat

## Danh sach deferred can note trung thuc khi showcase

- GitHub auth that
- Recommendation engine that
- GitHub sync backend that

## De xuat thu tu sua tiep

1. Chot cum social core: `04`, `05`, `08`, `10`
2. Chot cum marketplace/features: `12`, `13`, `14`, `15`
3. Polish cum tools/deferred: `16`, `17`, `18`
4. Chup lai mot vong audit sau cung va cap nhat contact sheet/showcase notes
