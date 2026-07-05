#!/usr/bin/env ruby
# frozen_string_literal: true
#
# App Store Connect スクリーンショット アップローダ (curl 経由)
#
#   asc.rb と同じ方針: JWT/JSON は Ruby、HTTP は curl に委譲。
#   バイナリ PUT (アセット本体) も curl の --data-binary で行う。
#
# 使い方 (すべて MornDash/ から):
#   ruby tools/asc/upload_screenshots.rb plan          # 何をするか表示のみ(読み取り)
#   ruby tools/asc/upload_screenshots.rb upload ja      # 1ロケールだけ実行
#   ruby tools/asc/upload_screenshots.rb upload all     # 全ロケール実行
#
# 各ロケールの対象セット(APP_IPHONE_67)の既存スクショは削除してから
# fastlane/screenshots_store/1284x2778/<locale>/01..06 を順にアップロードする。
#
require "json"
require "jwt"
require "openssl"
require "tempfile"
require "digest"

ROOT      = File.expand_path("../..", __dir__)
KEY_JSON  = File.join(ROOT, "fastlane", ".keys", "asc_api_key.json")
SHOTS_DIR = File.join(ROOT, "fastlane", "screenshots_store", "1284x2778")
BUNDLE_ID = "danchi.MornDash"
BASE      = "https://api.appstoreconnect.apple.com"
DISPLAY   = "APP_IPHONE_65" # 1284x2778 / 1242x2688 が入る 6.5" スロット

def token
  cfg = JSON.parse(File.read(KEY_JSON))
  key = OpenSSL::PKey::EC.new(cfg["key"])
  now = Time.now.to_i
  JWT.encode({ iss: cfg["issuer_id"], iat: now, exp: now + 1000, aud: "appstoreconnect-v1" },
             key, "ES256", { kid: cfg["key_id"], typ: "JWT" })
end

def http(method, path, body = nil)
  url = path.start_with?("http") ? path : "#{BASE}#{path}"
  args = ["curl", "-s", "-X", method, "-H", "Authorization: Bearer #{@token ||= token}"]
  tmp = nil
  if body
    tmp = Tempfile.new("asc")
    tmp.write(JSON.generate(body)); tmp.flush
    args += ["-H", "Content-Type: application/json", "-d", "@#{tmp.path}"]
  end
  args += ["-w", "\n%{http_code}", url]
  out = IO.popen(args, &:read)
  tmp&.close!
  raw, _, code = out.rpartition("\n")
  code = code.to_i
  if code >= 400
    warn "  ! HTTP #{code} #{method} #{path}"
    warn "    #{raw[0, 500]}"
    return nil
  end
  raw.empty? ? {} : JSON.parse(raw)
end

# uploadOperation に従いバイナリを PUT する(認証ヘッダは付けない)
def put_asset(op, file_path)
  offset = op["offset"] || 0
  length = op["length"] || File.size(file_path)
  slice  = File.binread(file_path, length, offset)
  tmp = Tempfile.new(["asset", ".bin"]); tmp.binmode
  tmp.write(slice); tmp.flush
  args = ["curl", "-s", "-X", (op["method"] || "PUT")]
  (op["requestHeaders"] || []).each { |h| args += ["-H", "#{h['name']}: #{h['value']}"] }
  args += ["--data-binary", "@#{tmp.path}", "-w", "\n%{http_code}", op["url"]]
  out = IO.popen(args, &:read)
  tmp.close!
  _, _, code = out.rpartition("\n")
  code.to_i < 400
end

def app_id
  @app_id ||= begin
    data = http("GET", "/v1/apps?limit=200")["data"]
    app = data.find { |a| a.dig("attributes", "bundleId") == BUNDLE_ID }
    abort("このキーからは #{BUNDLE_ID} が見えません") unless app
    app["id"]
  end
end

EDITABLE = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED
              INVALID_BINARY WAITING_FOR_REVIEW READY_FOR_REVIEW].freeze

def editable_version
  vers = http("GET", "/v1/apps/#{app_id}/appStoreVersions?limit=20")["data"]
  vers.find { |v| EDITABLE.include?(v.dig("attributes", "appStoreState")) } || vers.first
end

def localizations
  @locs ||= (http("GET", "/v1/appStoreVersions/#{editable_version['id']}/appStoreVersionLocalizations?limit=50")["data"] || [])
end

def local_locales
  Dir.children(SHOTS_DIR).select { |d| File.directory?(File.join(SHOTS_DIR, d)) }.sort
end

def files_for(locale)
  Dir.glob(File.join(SHOTS_DIR, locale, "*.png")).sort
end

# 対象ロケールの APP_IPHONE_67 セットを取得(なければ作成)。既存スクショは削除。
def ensure_clean_set(loc_id)
  sets = http("GET", "/v1/appStoreVersionLocalizations/#{loc_id}/appScreenshotSets")["data"] || []
  set  = sets.find { |s| s.dig("attributes", "screenshotDisplayType") == DISPLAY }
  unless set
    created = http("POST", "/v1/appScreenshotSets", {
      data: { type: "appScreenshotSets",
              attributes: { screenshotDisplayType: DISPLAY },
              relationships: { appStoreVersionLocalization: { data: { type: "appStoreVersionLocalizations", id: loc_id } } } }
    })
    set = created && created["data"]
    return nil unless set
  end
  # 既存スクショを削除
  existing = http("GET", "/v1/appScreenshotSets/#{set['id']}/appScreenshots")["data"] || []
  existing.each { |sc| http("DELETE", "/v1/appScreenshots/#{sc['id']}") }
  set["id"]
end

def upload_one(sc_set_id, file)
  size = File.size(file)
  name = File.basename(file)
  res = http("POST", "/v1/appScreenshots", {
    data: { type: "appScreenshots",
            attributes: { fileName: name, fileSize: size },
            relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: sc_set_id } } } }
  })
  return nil unless res && res["data"]
  sid = res["data"]["id"]
  ops = res.dig("data", "attributes", "uploadOperations") || []
  ops.each { |op| return nil unless put_asset(op, file) }
  md5 = Digest::MD5.hexdigest(File.binread(file))
  done = http("PATCH", "/v1/appScreenshots/#{sid}", {
    data: { type: "appScreenshots", id: sid,
            attributes: { uploaded: true, sourceFileChecksum: md5 } }
  })
  done ? sid : nil
end

def upload_locale(locale)
  loc = localizations.find { |l| l.dig("attributes", "locale") == locale }
  unless loc
    warn "  [#{locale}] ASC にロケールが無い → スキップ"
    return
  end
  files = files_for(locale)
  if files.empty?
    warn "  [#{locale}] 画像なし → スキップ"
    return
  end
  set_id = ensure_clean_set(loc["id"])
  unless set_id
    warn "  [#{locale}] セット取得/作成に失敗"
    return
  end
  ordered = []
  files.each do |f|
    sid = upload_one(set_id, f)
    if sid
      ordered << sid
      puts "  [#{locale}] ✓ #{File.basename(f)}"
    else
      puts "  [#{locale}] ✗ #{File.basename(f)} 失敗"
    end
  end
  # 表示順を 01..06 に固定
  unless ordered.empty?
    http("PATCH", "/v1/appScreenshotSets/#{set_id}/relationships/appScreenshots",
         { data: ordered.map { |id| { type: "appScreenshots", id: id } } })
  end
  puts "  [#{locale}] 完了: #{ordered.size}/#{files.size} 枚"
end

def cmd_plan
  ver = editable_version
  puts "App: #{BUNDLE_ID} (id #{app_id})"
  puts "対象 version: v#{ver.dig('attributes', 'versionString')} state=#{ver.dig('attributes', 'appStoreState')}"
  puts "表示タイプ: #{DISPLAY} (1284x2778)"
  puts "画像元: #{SHOTS_DIR.sub(ROOT + '/', '')}"
  puts "\nロケール別 枚数(ローカル → ASC ロケール有無):"
  asc = localizations.map { |l| l.dig("attributes", "locale") }
  local_locales.each do |loc|
    mark = asc.include?(loc) ? "✓" : "✗(ASC無)"
    puts "  #{loc.ljust(8)} #{files_for(loc).size}枚  #{mark}"
  end
  puts "\n実行: ruby tools/asc/upload_screenshots.rb upload <locale|all>"
end

def cmd_verify(locale)
  loc = localizations.find { |l| l.dig("attributes", "locale") == locale }
  return puts("  [#{locale}] ロケール無し") unless loc
  sets = http("GET", "/v1/appStoreVersionLocalizations/#{loc['id']}/appScreenshotSets")["data"] || []
  set  = sets.find { |s| s.dig("attributes", "screenshotDisplayType") == DISPLAY }
  return puts("  [#{locale}] #{DISPLAY} セット無し") unless set
  shots = http("GET", "/v1/appScreenshotSets/#{set['id']}/appScreenshots?limit=50")["data"] || []
  puts "  [#{locale}] #{shots.size}枚:"
  shots.each do |s|
    a = s["attributes"]
    puts "    - #{a['fileName']}  state=#{a.dig('assetDeliveryState', 'state')}  #{a['sourceFileChecksum']}"
  end
end

case ARGV[0]
when "plan"
  cmd_plan
when "verify"
  cmd_verify(ARGV[1] || "ja")
when "debug"
  locale = ARGV[1] || "ja"
  loc = localizations.find { |l| l.dig("attributes", "locale") == locale }
  set_id = ensure_clean_set(loc["id"])
  file = files_for(locale).first
  size = File.size(file)
  puts "file=#{file} size=#{size}"
  res = http("POST", "/v1/appScreenshots", {
    data: { type: "appScreenshots",
            attributes: { fileName: File.basename(file), fileSize: size },
            relationships: { appScreenshotSet: { data: { type: "appScreenshotSets", id: set_id } } } }
  })
  sid = res["data"]["id"]
  ops = res.dig("data", "attributes", "uploadOperations") || []
  puts "uploadOperations count=#{ops.size}"
  puts JSON.pretty_generate(ops)
  ops.each do |op|
    ok = put_asset(op, file)
    puts "PUT #{op['url'][0,60]}... -> #{ok ? 'ok' : 'FAIL'}"
  end
  md5 = Digest::MD5.hexdigest(File.binread(file))
  puts "md5=#{md5}"
  done = http("PATCH", "/v1/appScreenshots/#{sid}", {
    data: { type: "appScreenshots", id: sid, attributes: { uploaded: true, sourceFileChecksum: md5 } }
  })
  puts "PATCH resp state=#{done && done.dig('data','attributes','assetDeliveryState','state')}"
when "upload"
  target = ARGV[1]
  abort("使い方: upload <locale|all>") unless target
  if target == "all"
    local_locales.each { |l| puts "== #{l} =="; upload_locale(l) }
  else
    upload_locale(target)
  end
  puts "\n完了(審査提出はしていません)。ASC で確認してください。"
else
  puts "使い方: ruby tools/asc/upload_screenshots.rb {plan | upload <locale|all>}"
end
