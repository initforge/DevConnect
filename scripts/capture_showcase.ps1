$ErrorActionPreference = 'Stop'

$BaseUrl = 'http://127.0.0.1:8123'
$Session = 'showcase'
$OutputDir = 'output\playwright\audit_mobile_v3'

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
Push-Location $OutputDir

$routes = @(
  @{ Name = '01_login'; Url = "$BaseUrl/#/login" },
  @{ Name = '02_register'; Url = "$BaseUrl/#/register" },
  @{ Name = '03_onboarding'; Url = "$BaseUrl/#/onboarding" },
  @{ Name = '04_home_feed'; Url = "$BaseUrl/#/home" },
  @{ Name = '05_post_detail'; Url = "$BaseUrl/#/post/p1" },
  @{ Name = '06_explore'; Url = "$BaseUrl/#/explore" },
  @{ Name = '07_profile'; Url = "$BaseUrl/#/profile" },
  @{ Name = '08_create_post'; Url = "$BaseUrl/#/create-post" },
  @{ Name = '09_direct_message'; Url = "$BaseUrl/#/chat/conv1" },
  @{ Name = '10_chat_list'; Url = "$BaseUrl/#/chat" },
  @{ Name = '11_notifications'; Url = "$BaseUrl/#/notifications" },
  @{ Name = '12_project_marketplace'; Url = "$BaseUrl/#/projects" },
  @{ Name = '13_job_board'; Url = "$BaseUrl/#/jobs" },
  @{ Name = '14_leaderboard'; Url = "$BaseUrl/#/leaderboard" },
  @{ Name = '15_analytics'; Url = "$BaseUrl/#/analytics" },
  @{ Name = '16_code_playground'; Url = "$BaseUrl/#/playground" },
  @{ Name = '17_mentorship'; Url = "$BaseUrl/#/mentorship" },
  @{ Name = '18_live_code'; Url = "$BaseUrl/#/live-code" },
  @{ Name = '19_settings'; Url = "$BaseUrl/#/settings" },
  @{ Name = '20_search_results'; Url = "$BaseUrl/#/search?q=flutter" }
)

npx --yes @playwright/cli -s=$Session resize 390 844 | Out-Null

foreach ($route in $routes) {
  npx --yes @playwright/cli -s=$Session goto $route.Url | Out-Null
  Start-Sleep -Milliseconds 1400
  $target = $route.Name + '.png'
  npx --yes @playwright/cli -s=$Session screenshot --filename $target | Out-Null
  Write-Output "captured $($route.Name)"
}

Pop-Location
