#!/usr/bin/env ruby
# frozen_string_literal: true
#
# App Store Connect メタデータ管理ツール(curl 経由)
#
#   JWT 生成と JSON 処理は Ruby、HTTP 通信だけ curl に委譲する。
#   （この環境の rbenv Ruby は OpenSSL が壊れていて Net::HTTP が使えないため）
#
# 使い方:
#   ruby tools/asc/asc.rb status   # アプリ/バージョンの状態を表示
#   ruby tools/asc/asc.rb pull     # 既存メタデータを fastlane/metadata/<locale>/*.txt へ取得
#   ruby tools/asc/asc.rb push     # ローカルの *.txt を App Store Connect へ反映(差分のみ)
#
require "json"
require "jwt"
require "openssl"
require "tempfile"
require "fileutils"
require "shellwords"

ROOT       = File.expand_path("../..", __dir__)          # …/MornDash
KEY_JSON   = File.join(ROOT, "fastlane", ".keys", "asc_api_key.json")
META_DIR   = File.join(ROOT, "fastlane", "metadata")
BUNDLE_ID  = "danchi.MornDash"
BASE       = "https://api.appstoreconnect.apple.com"

# appInfoLocalization に載る項目 → ファイル名
APP_INFO_FIELDS = {
  "name"             => "name.txt",
  "subtitle"         => "subtitle.txt",
  "privacyPolicyUrl" => "privacy_url.txt"
}
# appStoreVersionLocalization に載る項目 → ファイル名
VERSION_FIELDS = {
  "description"      => "description.txt",
  "keywords"        => "keywords.txt",
  "promotionalText" => "promotional_text.txt",
  "marketingUrl"    => "marketing_url.txt",
  "supportUrl"      => "support_url.txt",
  "whatsNew"        => "release_notes.txt"
}
# 「編集可能」とみなすステート
EDITABLE = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED
              INVALID_BINARY WAITING_FOR_REVIEW READY_FOR_REVIEW].freeze

def token
  cfg = JSON.parse(File.read(KEY_JSON))
  key = OpenSSL::PKey::EC.new(cfg["key"])
  now = Time.now.to_i
  JWT.encode({ iss: cfg["issuer_id"], iat: now, exp: now + 1000, aud: "appstoreconnect-v1" },
             key, "ES256", { kid: cfg["key_id"], typ: "JWT" })
end

# curl 経由の HTTP。成功時はパース済み JSON(またはnil)を返す。
def http(method, path, body = nil)
  url = path.start_with?("http") ? path : "#{BASE}#{path}"
  args = ["curl", "-s", "-X", method,
          "-H", "Authorization: Bearer #{@token ||= token}"]
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
    warn "    #{raw[0, 400]}"
    return nil
  end
  raw.empty? ? {} : JSON.parse(raw)
end

def app_id
  @app_id ||= begin
    data = http("GET", "/v1/apps?limit=200")["data"]
    app = data.find { |a| a.dig("attributes", "bundleId") == BUNDLE_ID }
    abort("このキーからは #{BUNDLE_ID} が見えません") unless app
    app["id"]
  end
end

def editable_app_info
  infos = http("GET", "/v1/apps/#{app_id}/appInfos")["data"]
  infos.find { |i| EDITABLE.include?(i.dig("attributes", "state")) } ||
    infos.find { |i| i.dig("attributes", "state") != "READY_FOR_SALE" } || infos.first
end

def editable_version
  vers = http("GET", "/v1/apps/#{app_id}/appStoreVersions?limit=20")["data"]
  vers.find { |v| EDITABLE.include?(v.dig("attributes", "appStoreState")) } || vers.first
end

def cmd_status
  puts "App: #{BUNDLE_ID} (id #{app_id})"
  info = editable_app_info
  ver  = editable_version
  puts "編集対象 appInfo:  #{info['id']} state=#{info.dig('attributes', 'state')}" if info
  if ver
    a = ver["attributes"]
    puts "編集対象 version:  v#{a['versionString']} state=#{a['appStoreState']} (#{a['platform']})"
  end
  puts "\n言語別ロケール:"
  (http("GET", "/v1/appInfos/#{info['id']}/appInfoLocalizations")["data"] || []).each do |l|
    puts "  #{l.dig('attributes', 'locale')}"
  end
end

def cmd_pull
  info = editable_app_info
  ver  = editable_version
  wrote = 0
  # appInfoLocalizations
  (http("GET", "/v1/appInfos/#{info['id']}/appInfoLocalizations")["data"] || []).each do |loc|
    dir = File.join(META_DIR, loc.dig("attributes", "locale"))
    FileUtils.mkdir_p(dir)
    APP_INFO_FIELDS.each do |field, file|
      File.write(File.join(dir, file), loc.dig("attributes", field).to_s)
      wrote += 1
    end
  end
  # appStoreVersionLocalizations
  (http("GET", "/v1/appStoreVersions/#{ver['id']}/appStoreVersionLocalizations")["data"] || []).each do |loc|
    dir = File.join(META_DIR, loc.dig("attributes", "locale"))
    FileUtils.mkdir_p(dir)
    VERSION_FIELDS.each do |field, file|
      File.write(File.join(dir, file), loc.dig("attributes", field).to_s)
      wrote += 1
    end
  end
  puts "取得完了: #{wrote} ファイルを #{META_DIR.sub(ROOT + '/', '')} に書き出しました。"
  puts "git diff で内容を確認してください。"
end

def read_local(locale, file)
  path = File.join(META_DIR, locale, file)
  File.exist?(path) ? File.read(path).strip : nil
end

def patch_localizations(list, type, fields)
  list.each do |loc|
    locale = loc.dig("attributes", "locale")
    changed = {}
    fields.each do |field, file|
      local = read_local(locale, file)
      next if local.nil?
      remote = loc.dig("attributes", field).to_s
      changed[field] = local if local != remote
    end
    next if changed.empty?
    puts "  [#{locale}] 更新: #{changed.keys.join(', ')}"
    http("PATCH", "/v1/#{type}/#{loc['id']}",
         { data: { type: type, id: loc["id"], attributes: changed } })
  end
end

def cmd_push
  info = editable_app_info
  ver  = editable_version
  puts "反映先: appInfo #{info['id']} / version #{ver['id']}"
  patch_localizations(
    http("GET", "/v1/appInfos/#{info['id']}/appInfoLocalizations")["data"] || [],
    "appInfoLocalizations", APP_INFO_FIELDS
  )
  patch_localizations(
    http("GET", "/v1/appStoreVersions/#{ver['id']}/appStoreVersionLocalizations")["data"] || [],
    "appStoreVersionLocalizations", VERSION_FIELDS
  )
  puts "反映完了(審査提出はしていません)。"
end

case ARGV[0]
when "status" then cmd_status
when "pull"   then cmd_pull
when "push"   then cmd_push
else
  puts "使い方: ruby tools/asc/asc.rb {status|pull|push}"
end
