---
title: "Getting Started With Strands SDK and AWS Bedrock AgentCore"
date: 2026-09-18 00:00:00 -0500
categories: [AWS]
tags: [aws, cloud, ai, ml, opensource, beginner, ai/ml]
description: A writeup of how to get started with the Strands SDK and use AWS Bedrock and AgentCore to deploy your agents to AWS.
---

## Overview

I found out was Strands SDK was at an open-source AI conference in Durham, NC called All Things AI. Thanks to Darko Meszaros from AWS for opening the door for me to this wonderful piece of software. Did some tinkering after the conference and came up with the idea for this workshop that students could participate in and learn something from. Using AWS services is also right up my alley because of my involvement with the AWS Student Builder Group at UofSC and my Amazon SAA-C03 certification.

This write up will teach you how to download and install `python` and set up the AWS Strands SDK to create your own AI Agents. Strands equips you with
variety of choices to customize your agent harness to make them as effective as possible no matter the setting. We will also use Bedrock and AgentCore to
take our agents that we created locally to the cloud to make them accessible to our organization.

## Prerequisites

* `python` 3.12^
* AWS Account
* <$1 for tokens

## Definitions

Before we get started, its important to make sure we have the AI vocabulary down pat. \\
This includes:

* Tokens:
  * Unit of consumption for an LLM
  * Roughly 1 token ≈ 0.75 words. This is relevant because API costs and context limits are measured in tokens.
* Large Language Model (LLM):
  * A neural network trained on massive text datasets that can understand and generate human language.
  * The Brains of the operation
* Model;
  * The specific LLM that you choose
  * Examples: Claude Opus 5.5, Fable, Chat GPT-6.1 Sol, Gemini 4, Grok 4.7, etc.
* Agent
  * A program that wraps an LLM with tools and a system prompt so it can take actions, not just generate text.
  * The agent handles the loop:
    1. receive input
    2. decide to call tools
    3. pass results to the LLM
    4. return final output
* Tools
  * Specific skills or processes that an agent can use to accomplish a task you have given them
  * The agent can call tools during a conversation to interact with the outside world, i.e. read files, search the web, hit APIs, etc.
* System Prompt
  * Instructions given to the LLM before any user input. It defines the model's/agent's persona, behavior, and output format.
* AWS Bedrock
  * Amazon's managed service for accessing LLMs via an API.
  * Instead of running a model yourself, you send requests to Bedrock and it runs inference on AWS infrastructure.
* Model Context Protocol (MCP)
  * Developed by [Anthropic](https://anthropic.com)
  * An open protocol that standardizes how AI models connect to external tools, data sources, and services.
  * Think of it as a USB for AI
  * Any MCP-compatible tool can plug into any MCP-compatible model/agent without custom glue code.
* Harness
  * The harness is the environment in which the agent works.
  * Think of this as like Claude-code or Codex, Pi if you’re in the know.
  * Harnesses can boost or hinder the performance of a model
  * Milwaukee tools vs Ryobi tools
  * Provides things like controls, persistence, action, context

---

## Your Turn

Okay, so now that we got the boring stuff out the way, let's move to talking about how to actually use Strands and starting creating your own agents.

### 3 Steps to Get Started

Clone the GitHub repository

```sh
git clone https://github.com/ty-bennett/strands-sdk-workshop.git
```

Set your AWS credentials by reading the required ENV variables inside `env_setup.txt`

```sh
cat env_setup.txt
```

Setup the environment (you will need [python](https://www.python.org/downloads/) 3.12+ already installed )

```sh
# check python version make sure its 3.12 or higher
python –version # or
python3 –version

# make virtual env
python -m venv <venv name> 
or
python3 -m venv <venv name>

# activate venv
source <venv name>/bin/activate
source <venv name>/bin/activate.ps1
./<venv name>/Scripts/activate 

# install deps
pip install -r requirements.txt

```

## Getting started with Strands

Now, we have everything we need to get started including Python, dependencies, and AWS credentials setup

Here are a few lines of code to create a simple agent using a cheap Amazon Bedrock model.

```python
from strands.models import BedrockModel
from strands import Agent

from dotenv import load_dotenv
load_dotenv()

# feel free to try newer models for better performance, this comes with a cost, though
model = BedrockModel(model_id="amazon.nova-pro-v1:0")

# agent creation
agent = Agent(model=model)

# will run whenever you start the program
if __name__ == "__main__":
    agent("Give me a mean green apple pie recipe")
```

Result

```md
Of course! This "Mean, Zesty, & Green Apple Pie" recipe...
```

Additionally, if you want to save the recipe somewhere and read it using a markdown viewer like Obsidian

```sh
python simple_agent.py > pie.md
obsidian pie.md
```

### Interchangeable Models

We can also run the same code, but with a different model, let's try it.

```python
from strands.models import BedrockModel
from strands import Agent

from dotenv import load_dotenv
load_dotenv()

# more capable model, at a ~higher cost
model = BedrockModel(model_id="us.anthropic.claude-sonnet-5")

# agent
agent = Agent(model=model)

if __name__ == "__main__":
    agent("Give me a mean green apple pie recipe")
```

Results (note similar because this was old output)

```md
Of course! This "Mean, Zesty, & Green Apple Pie" recipe...
```

## Creating Tools

With Strands, we also have the ability to create and customize our own tools. We must mark the tool with the `@tool` decorator from Python and put a docstring underneath the tool to define its purpose and how it works, when to use it, what it expects as input and returns, etc. Put anything you like to help your agent reason to use the tool.\\
\\
Here, we are going to define a tool to help our agent figure out current time. Since models are pretrained, they have no idea about current events, so we must give
them access to find out information that is current or would require an external source that is not itself to lookup and get information. For example, current time:

```python
# We import datetime module from Python
from datetime import datetime
from strands import Agent, tool
from strands.models import BedrockModel
from dotenv import load_dotenv
load_dotenv()

# mark this function as a tool
@tool
def get_current_time() -> str:
  # put the tools purpose and what it does
    """Returns the current date and time so the agent knows when it is."""
    return datetime.now().strftime("It's %A, %B %d %Y at %I:%M %p")

# then when creating the agent, we give it the tool in a list of tools
agent = Agent(
    model=BedrockModel(model_id="amazon.nova-pro-v1:0"),
    tools=[get_current_time],
  # also give our agent a fun system prompt
    system_prompt="You are Forrest Gump from the movie, Forrest Gump, please respond as if you are Forrest and use grammer similar to him"
)
# then ask the agent 'what time is it?'
if __name__ == "__main__":
    agent("What time is it?")
```

> Well now, I'd say it's about 9:17 in the evening on a Tuesday, October 20th of 2026. That reminds me of when Lieutenant Dan and I would talk about shrimp at Bubba Gump Shrimp Company late in the evenings. But you know, time is just like running - you just keep going forward, one day at a time, like I did when I ran across America three and a half years. Nice to meet you!

{: .prompt-tip }
> Pretty neat right?

## Turning it into an academic assistant

A clock demonstrates tool calling, but some real assignment data makes the agent more useful to us.

The workshop uses CSV files with columns such as:

```csv
course,assignment,due_date,type,estimated_hours,status,notes
CSCE 350,Dynamic Programming Homework,2026-10-23,homework,3,not started,Review memoization
ENGL 101,Essay Draft,2026-10-25,essay,2,in progress,Add counterarguments
```

The `load_assignments` tool reads this file and handles the bookkeeping in Python. It checks required columns, skips rows marked `complete`, parses deadlines, and groups the remaining assignments into overdue, due today, due this week, and upcoming.

It then sorts assignments within each group using this score (it's arbitrary but a good example):

```python
priority = (2.0 * days_remaining) + estimated_hours
```

Lower scores will come first because they have a higher priority. For example, an assignment due tomorrow that needs three hours scores `5` beats one due in four days that needs one hour scores `9`.

This division of work is useful. Python calculates dates and priorities, while the model turns those results into a readable briefing.

The system prompt asks for sections such as `SITUATION`, `TODAY`, `THIS WEEK`, `HEADS UP`, and `TIP`. Those instructions guide the response, but they do not enforce a schema. An application that requires an exact structure should validate the output.

## Generating a study schedule

The next tool, `schedule_study_blocks`, converts the pending assignments into study sessions.

With the default settings, it:

* Starts at the next whole hour, no earlier than 9 a.m.
* Uses a daily scheduling window ending at 9 p.m.
* Splits assignments into sessions of at most two hours.
* Adds a 30-minute break between sessions of the same assignment.

The later examples export these sessions as an `.ics` calendar file, which you can import into a calendar application.

The repository includes different versions of this functionality. `agents/agent5.py` reads Google Calendar events and checks proposed sessions for overlap. `agents/agent6.py` adds S3 storage while retaining that integration.

The hosted `agent_core_agent_full.py` uses the assignment CSV to generate its schedule without reading Google Calendar. Its output is an importable file; it does not directly create Google Calendar events.

The scheduler also uses deadlines to determine priority without enforcing completion before each deadline. It is a starting scheduling algorithm, and its output still needs review.

## Moving the files into S3

A hosted application needs access to its inputs after your laptop disconnects.

The cloud version accepts an S3 URI:

```text
s3://YOUR_BUCKET/assignments/assignments.csv
```

Its helper functions read the object with Boto3 and expose the text to `csv.DictReader`. After generating the calendar, the application uploads it to S3 and returns a presigned download URL.

That gives us this flow:

```text
Assignment CSV in S3
        ↓
Python tools read and schedule assignments
        ↓
Calendar file uploaded to S3
        ↓
Briefing and download link returned to the caller
```

The hosted application uses an IAM execution role for AWS access. That role needs permission to invoke the model and access the relevant S3 objects.

## Hosting the agent with AgentCore

AgentCore Runtime provides the hosting environment. The application exposes an entrypoint using `BedrockAgentCoreApp`:

```python
from bedrock_agentcore import BedrockAgentCoreApp

app = BedrockAgentCoreApp()

@app.entrypoint
def invoke(payload):
    prompt = payload.get("prompt", "Give me my daily briefing.")
    return {"result": str(_get_agent()(prompt))}

if __name__ == "__main__":
    app.run()
```

This is a simplified version of the repository’s wrapper. The full implementation also accepts assignment and output paths.

The `_get_agent()` helper creates the Strands agent on its first use and reuses it within that Python process. Heavy imports are deferred until that first invocation, which reduces work during application startup. The first request still pays that initialization cost.

The workshop uses the Python AgentCore starter toolkit. Install it separately from the runtime dependencies:

```sh
python -m pip install bedrock-agentcore-starter-toolkit
```

Then configure the full hosted example:

```sh
agentcore configure \
  --entrypoint agent_core_agent_full.py \
  --requirements-file requirements-agentcore.txt \
  --region us-east-1
```

Review the configuration and execution role before deploying:

```sh
agentcore deploy
agentcore status
```

These commands follow the Python starter toolkit workflow. AWS also offers a newer CLI workflow, so use the documentation that matches your installed toolkit.

Replace the workshop’s default bucket paths with your own. The runtime must be able to read the assignment CSV and write the generated calendar.

Once deployed, a request can look like:

```sh
agentcore invoke '{
  "prompt": "Give me my daily briefing and schedule study blocks.",
  "assignments_file": "s3://YOUR_BUCKET/assignments/assignments.csv",
  "output_file": "study_schedule.ics"
}'
```

The caller needs permission to invoke the runtime. Deploying the application does not automatically make it publicly accessible.

## Making required actions explicit

One detail in the hosted implementation is especially useful: it has a fallback for calendar generation.

After the agent responds, the wrapper checks whether the response contains `Download link:`. If it does not, and scheduling is enabled, Python calls `schedule_study_blocks` directly and appends the result.

That puts a required action into application logic instead of depending entirely on the model following a prompt.

The current check is a text heuristic. A stronger implementation would track whether an upload actually succeeded and return the artifact location as a structured field.

That is where this workshop starts becoming application development: choosing which decisions the model can make, which operations belong in tools, and which outcomes your program must verify.

## Summary

I hope you enjoyed exploring Strands with me, it truly is fun to tinker with agentic AI if you have easy to use tools like this available to you. The Strands team is super awesome and they are very active in their Discord, and do a great job of receiving feedback from their community, that's why there's a TypeScript version of this SDK as well! Albeit, missing some features, but this is an active project so keep up on GitHub with their latest releases.

If you have any questions about anything or want to make a PR, reach me @ty-bennett on GitHub, or look at the bottom left of the screen to send me an email if you want to reach out.

Thanks for reading!

-Ty
