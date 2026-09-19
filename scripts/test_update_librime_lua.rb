#!/usr/bin/env ruby
require "tmpdir"
require "fileutils"

Dir.mktmpdir do |dir|
  FileUtils.mkdir_p(["#{dir}/scripts", "#{dir}/skills/rime-lua/assets", "#{dir}/bin"])
  FileUtils.cp(File.join(__dir__, "update_librime_lua.sh"), "#{dir}/scripts")
  target = "#{dir}/skills/rime-lua/assets/librime.lua"
  File.write("#{dir}/bin/curl", <<~SH)
    #!/bin/sh
    for arg do output="$arg"; done
    printf '%s\\n' "$CONTENT" > "$output"
    exit "$STATUS"
  SH
  File.chmod(0755, "#{dir}/bin/curl")
  [["---@meta rime", "0", true], ["invalid", "0", false], ["---@meta rime", "22", false]].each do |content, status, success|
    File.write(target, "original")
    result = system({"PATH" => "#{dir}/bin:#{ENV.fetch('PATH')}", "CONTENT" => content, "STATUS" => status},
                    "sh", "#{dir}/scripts/update_librime_lua.sh", chdir: "/", out: File::NULL)
    raise "unexpected exit status" unless result == success
    raise "unexpected file content" unless File.read(target) == (success ? "#{content}\n" : "original")
    raise "temporary file leaked" unless Dir.glob("#{target}.*").empty?
  end
end
puts "Update success, invalid content, and download failure checks passed."
