#!/usr/bin/env python

import requests
import subprocess
import os
import sys

chat_id = os.getenv("TELEGRAM_CHAT_ID", "")

bot_token = os.getenv("TELEGRAM_BOT_TOKEN", "")
chat_id = os.getenv("TELEGRAM_CHAT_ID", "")
project_id = os.getenv("CI_PROJECT_ID", 1)
branch = os.getenv("CI_COMMIT_BRANCH", "develop")
private_token = os.getenv("READ_ACCESS_TOKEN", "")
current_commit_sha = os.getenv("CI_COMMIT_SHA", "")
project_name = os.getenv("CI_PROJECT_NAME", "unknown")
project_group = os.getenv("CI_PROJECT_NAMESPACE", "unknown")
project_url = os.getenv("CI_PROJECT_URL", "/")
pipeline_id = os.getenv("CI_PIPELINE_ID", "0")
pipeline_iid = os.getenv("CI_PIPELINE_IID", "0")
job_status = os.getenv("CI_JOB_STATUS", "failed")
job_stage = os.getenv("CI_JOB_STAGE", "test")
job_name = os.getenv("CI_JOB_NAME", "job-name")
api_url = os.getenv("CI_API_V4_URL")

if len(sys.argv) == 2:
    print(sys.argv[1])
    id = sys.argv[1].split("=")
    if len(id) == 2 and id[0] == "chat_id" and id[1] != "":
        chat_id = id[1]


def validate():
    if private_token == "":
        print("READ_ACCESS_TOKEN is undefined")
        exit(1)

    if bot_token == "":
        print("TELEGRAM_BOT_TOKEN is undefined")
        exit(1)

    if chat_id == "":
        print("TELEGRAM_CHAT_ID is undefined")
        exit(1)


def telegram_bot_sendtext(message):
    send_text = (
        "https://api.telegram.org/bot"
        + bot_token
        + "/sendMessage?chat_id="
        + chat_id
        + "&parse_mode=HTML&text="
        + message
    )

    requests.get(send_text)


def get_previous_commit():
    url = f"{api_url}/projects/{project_id}/pipelines?ref={branch}&scope=finished"
    response = requests.get(url, headers={"PRIVATE-TOKEN": private_token})
    response_json = response.json()
    if len(response_json) > 0:
        return response_json[0]["sha"]

    return ""


def get_commits():
    previous_commit_sha = get_previous_commit()
    if previous_commit_sha == "":
        return "No pipeline history"

    cmd = [
        "git",
        "log",
        "--format=%s - %an",
        "--no-merges",
        f"{previous_commit_sha}..{current_commit_sha}",
    ]
    lines = subprocess.run(cmd, capture_output=True).stdout.decode().split("\n")
    commits = ""

    for l in lines:
        if l != "":
            commits += "— " + l + "\n"

    if commits == "":
        commits = "No changes"

    return commits


def build_message():
    status_icon = "🟢"
    if job_status == "failed":
        status_icon = "🔴"
    if job_status == "cancelled":
        status_icon = "⚪"

    return f"""

  {status_icon} <b>{job_stage}</b> / <b>{job_name}</b>
  %23{job_status} %23{project_group}_{project_name}

  <b>{project_group} / {project_name}</b>
  Build: <a href="{project_url}/-/pipelines/{pipeline_id}">{pipeline_iid}</a>
  Branch: <b>{branch}</b>

  <i>Commits:</i>
  {get_commits()}"""


validate()

telegram_bot_sendtext(build_message())
