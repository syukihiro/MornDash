#!/usr/bin/env ruby
# frozen_string_literal: true
#
# App Store Connect サブスクリプション・ローカリゼーション管理ツール(curl 経由)
#
#   asc.rb と同じ流儀: JWT 生成と JSON 処理は Ruby、HTTP 通信だけ curl に委譲する。
#   asc.rb は App/Version 側のメタデータのみ扱うため、IAP(サブスク)は本ツールが担当する。
#
# 使い方(すべて MornDash/ から実行):
#   ruby tools/asc/subscriptions.rb status   # グループ/サブスクと既存ローカリゼーションを表示
#   ruby tools/asc/subscriptions.rb push     # subscription_localizations.json を反映(無ければ作成/差分は更新)
#
# 反映元: tools/asc/subscription_localizations.json
# 反映するのは「表示名 / 説明」のみ。価格・審査用スクショ・審査提出は対象外(ASC 画面で行う)。
#
require "json"
require "jwt"
require "openssl"
require "tempfile"

ROOT      = File.expand_path("../..", __dir__)          # …/MornDash
KEY_JSON  = File.join(ROOT, "fastlane", ".keys", "asc_api_key.json")
DATA_JSON = File.join(__dir__, "subscription_localizations.json")
BUNDLE_ID = "danchi.MornDash"
BASE      = "https://api.appstoreconnect.apple.com"

def token
  cfg = JSON.parse(File.read(KEY_JSON))
  key = OpenSSL::PKey::EC.new(cfg["key"])
  now = Time.now.to_i
  JWT.encode({ iss: cfg["issuer_id"], iat: now, exp: now + 1000, aud: "appstoreconnect-v1" },
             key, "ES256", { kid: cfg["key_id"], typ: "JWT" })
end

# curl 経由の HTTP。成功時はパース済み JSON(またはnil)。
def http(method, path, body = nil)
  url = path.start_with?("http") ? path : "#{BASE}#{path}"
  args = ["curl", "-s", "-X", method,
          "-H", "Authorization: Bearer #{@token ||= token}"]
  tmp = nil
  if body
    tmp = Tempfile.new("asc-sub")
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

def app_id
  @app_id ||= begin
    data = http("GET", "/v1/apps?limit=200")["data"]
    app = data.find { |a| a.dig("attributes", "bundleId") == BUNDLE_ID }
    abort("このキーからは #{BUNDLE_ID} が見えません") unless app
    app["id"]
  end
end

def data_config
  @data_config ||= JSON.parse(File.read(DATA_JSON))
end

# 対象の productId を含むサブスクリプショングループを探す。
# 戻り値: { group: {id, ref}, subs: { productId => subId } }
def find_group_and_subs
  want = data_config["productIds"]
  groups = http("GET", "/v1/apps/#{app_id}/subscriptionGroups?limit=200")["data"] || []
  groups.each do |g|
    subs = http("GET", "/v1/subscriptionGroups/#{g['id']}/subscriptions?limit=200")["data"] || []
    map = {}
    subs.each { |s| map[s.dig("attributes", "productId")] = s["id"] }
    next unless want.all? { |pid| map.key?(pid) }
    return { group: { "id" => g["id"], "ref" => g.dig("attributes", "referenceName") }, subs: map }
  end
  abort("productIds #{want.inspect} を全て含むサブスクグループが見つかりません")
end

def existing_by_locale(list)
  (list || []).each_with_object({}) { |l, h| h[l.dig("attributes", "locale")] = l }
end

# --- group localizations ---
def push_group_localizations(group_id)
  existing = existing_by_locale(
    http("GET", "/v1/subscriptionGroups/#{group_id}/subscriptionGroupLocalizations?limit=200")["data"]
  )
  data_config["group"].each do |locale, attrs|
    want = { "name" => attrs["name"] }
    cur = existing[locale]
    if cur.nil?
      puts "  [group/#{locale}] 作成: name=#{want['name']}"
      http("POST", "/v1/subscriptionGroupLocalizations", {
        data: {
          type: "subscriptionGroupLocalizations",
          attributes: want.merge("locale" => locale),
          relationships: { subscriptionGroup: { data: { type: "subscriptionGroups", id: group_id } } }
        }
      })
    elsif cur.dig("attributes", "name") != want["name"]
      puts "  [group/#{locale}] 更新: name=#{want['name']}"
      http("PATCH", "/v1/subscriptionGroupLocalizations/#{cur['id']}",
           { data: { type: "subscriptionGroupLocalizations", id: cur["id"], attributes: want } })
    end
  end
end

# --- subscription localizations ---
def push_subscription_localizations(product_id, sub_id)
  existing = existing_by_locale(
    http("GET", "/v1/subscriptions/#{sub_id}/subscriptionLocalizations?limit=200")["data"]
  )
  data_config["subscription"].each do |locale, attrs|
    want = { "name" => attrs["name"], "description" => attrs["description"] }
    cur = existing[locale]
    if cur.nil?
      puts "  [#{product_id}/#{locale}] 作成: #{want['name']} — #{want['description']}"
      http("POST", "/v1/subscriptionLocalizations", {
        data: {
          type: "subscriptionLocalizations",
          attributes: want.merge("locale" => locale),
          relationships: { subscription: { data: { type: "subscriptions", id: sub_id } } }
        }
      })
    elsif cur.dig("attributes", "name") != want["name"] ||
          cur.dig("attributes", "description") != want["description"]
      puts "  [#{product_id}/#{locale}] 更新: #{want['name']} — #{want['description']}"
      http("PATCH", "/v1/subscriptionLocalizations/#{cur['id']}",
           { data: { type: "subscriptionLocalizations", id: cur["id"], attributes: want } })
    end
  end
end

def cmd_status
  puts "App: #{BUNDLE_ID} (id #{app_id})"
  found = find_group_and_subs
  g = found[:group]
  puts "グループ: #{g['ref']} (id #{g['id']})"
  glocs = existing_by_locale(
    http("GET", "/v1/subscriptionGroups/#{g['id']}/subscriptionGroupLocalizations?limit=200")["data"]
  )
  puts "  グループ表示名ローカリゼーション: #{glocs.keys.sort.join(', ')}" unless glocs.empty?
  puts "  グループ表示名ローカリゼーション: (なし)" if glocs.empty?
  found[:subs].each do |pid, sid|
    locs = existing_by_locale(
      http("GET", "/v1/subscriptions/#{sid}/subscriptionLocalizations?limit=200")["data"]
    )
    puts "  #{pid} (id #{sid}): #{locs.empty? ? '(ローカリゼーションなし)' : locs.keys.sort.join(', ')}"
  end
  puts "\nJSON側ロケール: #{data_config['subscription'].keys.sort.join(', ')}"
end

def cmd_push
  found = find_group_and_subs
  puts "反映先グループ: #{found[:group]['ref']} (id #{found[:group]['id']})"
  push_group_localizations(found[:group]["id"])
  found[:subs].each { |pid, sid| push_subscription_localizations(pid, sid) }
  puts "反映完了(表示名/説明のみ。価格・審査用スクショ・審査提出は ASC 画面で。)"
end

case ARGV[0]
when "status" then cmd_status
when "push"   then cmd_push
else
  puts "使い方: ruby tools/asc/subscriptions.rb {status|push}"
end
