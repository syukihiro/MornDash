#!/usr/bin/env ruby
# frozen_string_literal: true
#
# App Store Connect API キー(.p8)から fastlane 用の asc_api_key.json を生成する。
#
# 使い方:
#   ruby fastlane/.keys/generate_key_json.rb <KeyID> <IssuerID> <path/to/AuthKey_XXXX.p8>
#
# 例:
#   ruby fastlane/.keys/generate_key_json.rb ABC123DEFG \
#     11aa22bb-3333-4444-5555-66cc77dd88ee ~/Downloads/AuthKey_ABC123DEFG.p8
#
require "json"

key_id, issuer_id, p8_path = ARGV
if key_id.nil? || issuer_id.nil? || p8_path.nil?
  abort("usage: ruby generate_key_json.rb <KeyID> <IssuerID> <path/to/AuthKey_XXXX.p8>")
end
abort("見つかりません: #{p8_path}") unless File.exist?(p8_path)

out_path = File.join(__dir__, "asc_api_key.json")
File.write(out_path, JSON.pretty_generate(
  "key_id" => key_id,
  "issuer_id" => issuer_id,
  "key" => File.read(p8_path),
  "in_house" => false
))
puts "生成しました: #{out_path}"
