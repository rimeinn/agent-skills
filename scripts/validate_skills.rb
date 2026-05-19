#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"

ROOT = File.expand_path("..", __dir__)
SKILLS_DIR = File.join(ROOT, "skills")
MAX_SKILL_LINES = 500
NAME_RE = /\A[a-z0-9]+(-[a-z0-9]+)*\z/

def fail_with(message)
  warn(message)
  exit 1
end

def read_frontmatter(path)
  text = File.read(path)
  match = text.match(/\A---\n(.*?)\n---\n/m)
  fail_with("missing YAML frontmatter: #{path}") unless match

  [YAML.safe_load(match[1]), text]
rescue Psych::SyntaxError => e
  fail_with("invalid YAML frontmatter in #{path}: #{e.message}")
end

def local_markdown_links(text)
  text.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.filter_map do |target|
    next if target.match?(/\A(?:https?:|mailto:|#)/)

    target.split("#", 2).first
  end
end

skill_paths = Dir.glob(File.join(SKILLS_DIR, "*", "SKILL.md")).sort
fail_with("no skills found") if skill_paths.empty?

skill_paths.each do |skill_path|
  skill_dir = File.dirname(skill_path)
  data, text = read_frontmatter(skill_path)
  name = data["name"]
  description = data["description"]
  dirname = File.basename(skill_dir)

  fail_with("missing name: #{skill_path}") unless name
  fail_with("bad skill name #{name.inspect}: #{skill_path}") unless name.match?(NAME_RE) && name.length <= 64 && !name.include?("--")
  fail_with("skill name #{name.inspect} must match directory #{dirname.inspect}") unless name == dirname
  fail_with("missing description: #{skill_path}") unless description && !description.strip.empty?
  fail_with("description too long in #{skill_path}") if description.length > 1024

  line_count = text.lines.count
  fail_with("#{skill_path} has #{line_count} lines, expected <= #{MAX_SKILL_LINES}") if line_count > MAX_SKILL_LINES

  local_markdown_links(text).each do |link|
    target = File.expand_path(link, skill_dir)
    fail_with("broken local link #{link.inspect} in #{skill_path}") unless File.exist?(target)
  end

  openai_path = File.join(skill_dir, "agents", "openai.yaml")
  fail_with("missing agents/openai.yaml for #{name}") unless File.exist?(openai_path)

  openai = YAML.safe_load(File.read(openai_path))
  interface = openai.fetch("interface")
  short_description = interface.fetch("short_description")
  default_prompt = interface.fetch("default_prompt")
  fail_with("short_description too short in #{openai_path}") if short_description.length < 25
  fail_with("short_description too long in #{openai_path}") if short_description.length > 64
  fail_with("default_prompt must mention $#{name} in #{openai_path}") unless default_prompt.include?("$#{name}")
end

Dir.glob(File.join(SKILLS_DIR, "*", "references", "*.md")).sort.each do |reference_path|
  text = File.read(reference_path)
  fail_with("reference should not contain SKILL frontmatter: #{reference_path}") if text.start_with?("---\n")

  local_markdown_links(text).each do |link|
    target = File.expand_path(link, File.dirname(reference_path))
    fail_with("broken local link #{link.inspect} in #{reference_path}") unless File.exist?(target)
  end
end

puts "Validated #{skill_paths.length} skills."
