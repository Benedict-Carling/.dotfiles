#!/bin/bash

# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title standup
# @raycast.mode inline
# @raycast.refreshTime 1h

# Optional parameters:
# @raycast.icon 🤖

# Documentation:
# @raycast.description Generate standup template
# @raycast.author Benedict Carling

today=$(date -u +"%Y-%m-%d")
yesterday=$(date -u -v -1d +"%Y-%m-%d")

output_today=$(gh search prs --author=@me --merged-at "$today" --json number,title,updatedAt,url --template '{{range .}}• [#{{.number}} - {{.title}}]({{.url}}) - {{timeago .updatedAt}}
{{end}}')

output_yesterday=$(gh search prs --author=@me --merged-at "$yesterday" --json number,title,updatedAt,url --template '{{range .}}• [#{{.number}} - {{.title}}]({{.url}}) - {{timeago .updatedAt}}
{{end}}')

open_prs=$(gh search prs --author=@me --state=open --json number,title,updatedAt,url --template '{{range .}}• [#{{.number}} - {{.title}}]({{.url}}) - {{timeago .updatedAt}}
{{end}}')

response=$(curl \
  -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: $LINEAR_API_TOKEN" \
  --data '{
    "query": "{ issues(filter: { assignee: { email: { eq: \"ben.c@mytos.bio\" } } state: { type: { eq: \"started\" } } }) { nodes { id title url number state {  name type} } } }"
  }' \
  https://api.linear.app/graphql)
  
linear_active=$(echo "$response" | jq -r '.data.issues.nodes[] |
  "  • [MYT-\(.number)](\(.url)) - \(.title) - State: \(.state.name)" +
  if .state.name == "In Progress" then " :large_orange_circle:" else "" end +
  if .state.name == "In Review" then " :large_green_circle:" else "" end')

echo ":newspaper: Updates:"
echo "• PRs open :open_book::"
echo "$open_prs" | awk '{print "    " $0}'
echo "• PRs merged today and yesterday :closed_book::"
echo "$output_today" | awk '{print "    " $0}'
echo "$output_yesterday" | awk '{print "    " $0}'
echo ":calendar:  Priorities for today:"
echo "• Active tickets :linear::"
echo "$linear_active" | awk '{print "    " $0}'

# Copy output to clipboard
{
    echo ":newspaper: Updates:"
    echo "• PRs open :open_book::"
    echo "$open_prs" | awk '{print "    " $0}'
    echo "• PRs merged today and yesterday :closed_book::"
    echo "$output_today" | awk '{print "    " $0}'
    echo "$output_yesterday" | awk '{print "    " $0}'
    echo ":calendar:  Priorities for today:"
    echo "• Active tickets :linear::"
    echo "$linear_active" | awk '{print "    " $0}'
} | pbcopy
