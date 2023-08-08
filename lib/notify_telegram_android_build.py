#!/usr/bin/env python

import requests
import os
import sys

chat_id = os.getenv("TELEGRAM_CHAT_ID", "")

bot_token = os.getenv("TELEGRAM_BOT_TOKEN", "")
chat_id = os.getenv("TELEGRAM_CHAT_ID", "")

branch = os.getenv("CI_COMMIT_BRANCH", "develop")
project_name = os.getenv("CI_PROJECT_NAME", "unknown")
project_group = os.getenv("CI_PROJECT_NAMESPACE", "unknown")
project_url = os.getenv("CI_PROJECT_URL", "/")
pipeline_id = os.getenv("CI_PIPELINE_ID", "0")
pipeline_iid = os.getenv("CI_PIPELINE_IID", "0")
job_status = os.getenv("CI_JOB_STATUS", "failed")
job_stage = os.getenv("CI_JOB_STAGE", "test")
job_name = os.getenv("CI_JOB_NAME", "job-name")
artifact_download_url = os.getenv("ARTIFACT_DOWNLOAD_URL", "")
version_name = os.getenv("VERSION_NAME", "0.0.0")
version_code = os.getenv("VERSION_CODE", "0")

if len(sys.argv) == 2:
    print(sys.argv[1])
    id = sys.argv[1].split("=")
    if len(id) == 2 and id[0] == "chat_id":
        chat_id = id[1]


def validate():
    if bot_token == "":
        print("TELEGRAM_BOT_TOKEN is undefined")
        exit(1)

    if chat_id == "":
        print("TELEGRAM_CHAT_ID is undefined")
        exit(0)


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


def build_message():
    status_icon = "🟢"
    if job_status == "failed":
        status_icon = "🔴"
    if job_status == "cancelled":
        status_icon = "⚪"

    return f"""

  {status_icon} / <b>{job_name}</b>
  %23{job_status} %23{project_group}_{project_name}

  <b>{project_group} / {project_name}</b>
  Android: <a href="{artifact_download_url}">{version_name}-{version_code}</a>
  Build: <a href="{project_url}/-/pipelines/{pipeline_id}">{pipeline_iid}</a>
  Branch: <b>{branch}</b>"""


validate()

telegram_bot_sendtext(build_message())
