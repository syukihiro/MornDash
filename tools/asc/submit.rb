#!/usr/bin/env ruby
# frozen_string_literal: true
#
# バージョン作成 / ビルド紐付け / 審査提出
#
#   ruby tools/asc/submit.rb create 1.0.1     # READY_FOR_SALE から新バージョンを作成
#   ruby tools/asc/submit.rb attach <buildId> # 編集中バージョンにビルドを紐付け
#   ruby tools/asc/submit.rb submit           # reviewSubmissions で審査提出
#   ruby tools/asc/submit.rb builds           # 最近のビルド一覧
#   ruby tools/asc/submit.rb status           # バージョンと提出状況
#
require "json"
require "jwt"
require "openssl"
require "tempfile"

ROOT      = File.expand_path("../..", __dir__)
KEY_JSON  = File.join(ROOT, "fastlane", ".keys", "asc_api_key.json")
BUNDLE_ID = "danchi.MornDash"
BASE      = "https://api.appstoreconnect.apple.com"
EDITABLE  = %w[PREPARE_FOR_SUBMISSION DEVELOPER_REJECTED REJECTED METADATA_REJECTED
               INVALID_BINARY WAITING_FOR_REVIEW READY_FOR_REVIEW].freeze

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
  parsed = raw.empty? ? {} : (JSON.parse(raw) rescue { "raw" => raw[0, 800] })
  if code >= 400
    warn "  ! HTTP #{code} #{method} #{path}"
    warn "    #{raw[0, 800]}"
    return nil
  end
  parsed
end

def app_id
  @app_id ||= begin
    data = http("GET", "/v1/apps?limit=200")["data"]
    app = data.find { |a| a.dig("attributes", "bundleId") == BUNDLE_ID }
    abort("app not found") unless app
    app["id"]
  end
end

def versions
  http("GET", "/v1/apps/#{app_id}/appStoreVersions?limit=20")["data"] || []
end

def editable_version
  versions.find { |v| EDITABLE.include?(v.dig("attributes", "appStoreState")) }
end

def cmd_status
  puts "App #{BUNDLE_ID} (#{app_id})"
  versions.each do |v|
    a = v["attributes"]
    puts "  v#{a['versionString']} #{a['appStoreState']} id=#{v['id']}"
  end
  subs = http("GET", "/v1/apps/#{app_id}/reviewSubmissions?limit=10")
  (subs && subs["data"] || []).each do |s|
    a = s["attributes"]
    puts "  submission #{s['id']} state=#{a['state']} submittedDate=#{a['submittedDate']}"
  end
end

def cmd_builds
  # /v1/builds?filter[app]= は空を返すことがあるため、apps 配下を使う（YouTrainy/WaitOn と同じキー）
  builds = http("GET", "/v1/apps/#{app_id}/builds?limit=20")["data"] || []
  if builds.empty?
    puts "(builds empty)"
    return
  end
  builds.sort_by { |b| b.dig("attributes", "uploadedDate").to_s }.reverse.each do |b|
    a = b["attributes"]
    puts "#{b['id']}  version=#{a['version']}  processing=#{a['processingState']}  expired=#{a['expired']}  uploaded=#{a['uploadedDate']}"
  end
end

def cmd_create(version_string)
  abort("version required") if version_string.nil? || version_string.empty?
  existing = versions.find { |v| v.dig("attributes", "versionString") == version_string }
  if existing
    puts "既に v#{version_string} があります: #{existing['id']} state=#{existing.dig('attributes', 'appStoreState')}"
    return
  end
  res = http("POST", "/v1/appStoreVersions", {
    data: {
      type: "appStoreVersions",
      attributes: { platform: "IOS", versionString: version_string },
      relationships: { app: { data: { type: "apps", id: app_id } } }
    }
  })
  abort("create failed") unless res
  v = res["data"]
  puts "作成: v#{v.dig('attributes', 'versionString')} id=#{v['id']} state=#{v.dig('attributes', 'appStoreState')}"
end

def cmd_attach(build_id)
  abort("build id required") if build_id.nil? || build_id.empty?
  ver = editable_version || abort("編集可能なバージョンがありません。先に create してください。")
  puts "紐付け: version #{ver['id']} ← build #{build_id}"
  res = http("PATCH", "/v1/appStoreVersions/#{ver['id']}", {
    data: {
      type: "appStoreVersions",
      id: ver["id"],
      relationships: {
        build: { data: { type: "builds", id: build_id } }
      }
    }
  })
  abort("attach failed") unless res
  puts "紐付け完了"
end

def cmd_submit
  ver = editable_version || abort("編集可能なバージョンがありません")
  puts "対象: v#{ver.dig('attributes', 'versionString')} state=#{ver.dig('attributes', 'appStoreState')}"

  # Reuse open submission if present
  existing = (http("GET", "/v1/apps/#{app_id}/reviewSubmissions?limit=10")["data"] || [])
               .find { |s| %w[READY_FOR_REVIEW UNRESOLVED].include?(s.dig("attributes", "state")) || s.dig("attributes", "state") == "WAITING_FOR_REVIEW" }
  # Actually open states before submit: READY_FOR_REVIEW means items added but not submitted?
  # Create fresh if needed
  open_sub = (http("GET", "/v1/apps/#{app_id}/reviewSubmissions?limit=10")["data"] || [])
               .find { |s| s.dig("attributes", "state") == "READY_FOR_REVIEW" }

  if open_sub.nil?
    # Also try creating; 409 means reuse
    created = http("POST", "/v1/reviewSubmissions", {
      data: {
        type: "reviewSubmissions",
        attributes: { platform: "IOS" },
        relationships: { app: { data: { type: "apps", id: app_id } } }
      }
    })
    if created
      open_sub = created["data"]
      puts "reviewSubmission 作成: #{open_sub['id']}"
    else
      # fetch again
      open_sub = (http("GET", "/v1/apps/#{app_id}/reviewSubmissions?limit=10")["data"] || []).first
      abort("reviewSubmission を取得できません") unless open_sub
      puts "既存 reviewSubmission を使用: #{open_sub['id']} state=#{open_sub.dig('attributes', 'state')}"
    end
  else
    puts "既存 reviewSubmission を使用: #{open_sub['id']} state=#{open_sub.dig('attributes', 'state')}"
  end

  item = http("POST", "/v1/reviewSubmissionItems", {
    data: {
      type: "reviewSubmissionItems",
      relationships: {
        reviewSubmission: { data: { type: "reviewSubmissions", id: open_sub["id"] } },
        appStoreVersion: { data: { type: "appStoreVersions", id: ver["id"] } }
      }
    }
  })
  if item
    puts "item 追加: #{item.dig('data', 'id')}"
  else
    puts "item 追加はスキップ/既存の可能性"
  end

  res = http("PATCH", "/v1/reviewSubmissions/#{open_sub['id']}", {
    data: {
      type: "reviewSubmissions",
      id: open_sub["id"],
      attributes: { submitted: true }
    }
  })
  abort("submit failed") unless res
  a = res.dig("data", "attributes") || {}
  puts "提出完了: state=#{a['state']} submittedDate=#{a['submittedDate']}"
end

case ARGV[0]
when "status" then cmd_status
when "builds" then cmd_builds
when "create" then cmd_create(ARGV[1])
when "attach" then cmd_attach(ARGV[1])
when "submit" then cmd_submit
else
  puts "使い方: ruby tools/asc/submit.rb {status|builds|create <ver>|attach <buildId>|submit}"
end
