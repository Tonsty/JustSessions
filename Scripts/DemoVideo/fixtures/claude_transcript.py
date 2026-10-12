"""Writes Claude Code session files in the record shape Claude Code itself saves."""
import json
import uuid
from datetime import timedelta, timezone
from pathlib import Path

CLAUDE_VERSION = "2.1.296"
MODEL = "claude-opus-4-6"


def iso(moment):
    return moment.astimezone(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


class ClaudeTranscript:
    """One session: user prompts, assistant replies, and tool calls with their results, seven seconds apart."""

    def __init__(self, cwd, session_id, started_at, branch="main"):
        self.cwd = str(cwd)
        self.session_id = session_id
        self.moment = started_at
        self.branch = branch
        self.records = []
        self.parent = None

    def _base(self, record_type):
        self.moment += timedelta(seconds=7)
        record = {"parentUuid": self.parent, "isSidechain": False, "userType": "external", "cwd": self.cwd,
                  "sessionId": self.session_id, "version": CLAUDE_VERSION, "gitBranch": self.branch,
                  "type": record_type, "uuid": str(uuid.uuid4()), "timestamp": iso(self.moment)}
        self.parent = record["uuid"]
        return record

    def user(self, text):
        record = self._base("user")
        record["message"] = {"role": "user", "content": text}
        self.records.append(record)

    def assistant(self, *blocks):
        record = self._base("assistant")
        stop_reason = "tool_use" if any(block["type"] == "tool_use" for block in blocks) else "end_turn"
        record["message"] = {"id": "msg_" + uuid.uuid4().hex[:24], "type": "message", "role": "assistant",
                             "model": MODEL, "content": list(blocks), "stop_reason": stop_reason,
                             "stop_sequence": None,
                             "usage": {"input_tokens": 1200, "output_tokens": 240, "cache_read_input_tokens": 0,
                                       "cache_creation_input_tokens": 0}}
        record["requestId"] = "req_" + uuid.uuid4().hex[:24]
        self.records.append(record)

    def text(self, text):
        self.assistant({"type": "text", "text": text})

    def tool(self, name, tool_input, result_text, tool_use_result):
        tool_use_id = "toolu_" + uuid.uuid4().hex[:24]
        self.assistant({"type": "tool_use", "id": tool_use_id, "name": name, "input": tool_input})
        record = self._base("user")
        record["message"] = {"role": "user", "content": [
            {"tool_use_id": tool_use_id, "type": "tool_result", "content": result_text, "is_error": False}]}
        record["toolUseResult"] = tool_use_result
        self.records.append(record)

    def bash(self, command, description, stdout):
        self.tool("Bash", {"command": command, "description": description}, stdout,
                  {"stdout": stdout, "stderr": "", "interrupted": False, "isImage": False})

    def read(self, relative_path, content):
        file_path = str(Path(self.cwd) / relative_path)
        numbered = "\n".join(f"{index:>6}\t{line}" for index, line in enumerate(content.splitlines(), 1))
        self.tool("Read", {"file_path": file_path}, numbered,
                  {"type": "text", "file": {"filePath": file_path, "content": content,
                                            "numLines": len(content.splitlines()), "startLine": 1,
                                            "totalLines": len(content.splitlines())}})

    def edit(self, relative_path, original_file, old_string, new_string):
        file_path = str(Path(self.cwd) / relative_path)
        old_lines = original_file.splitlines()
        start = original_file[: original_file.index(old_string)].count("\n") + 1
        old_block = old_string.splitlines()
        new_block = new_string.splitlines()
        context_before = old_lines[max(0, start - 3): start - 1]
        context_after = old_lines[start - 1 + len(old_block): start - 1 + len(old_block) + 2]
        patch_lines = ([" " + line for line in context_before] + ["-" + line for line in old_block]
                       + ["+" + line for line in new_block] + [" " + line for line in context_after])
        hunk_start = start - len(context_before)
        patch = [{"oldStart": hunk_start, "oldLines": len(context_before) + len(old_block) + len(context_after),
                  "newStart": hunk_start, "newLines": len(context_before) + len(new_block) + len(context_after),
                  "lines": patch_lines}]
        self.tool("Edit", {"file_path": file_path, "old_string": old_string, "new_string": new_string},
                  f"The file {file_path} has been updated successfully.",
                  {"filePath": file_path, "oldString": old_string, "newString": new_string,
                   "originalFile": original_file, "structuredPatch": patch, "userModified": False,
                   "replaceAll": False})

    def save(self, claude_directory, title=None):
        if title:
            self.records.append({"type": "custom-title", "customTitle": title, "sessionId": self.session_id})
        folder = claude_directory / "projects" / "".join(c if c.isalnum() else "-" for c in self.cwd)
        folder.mkdir(parents=True, exist_ok=True)
        path = folder / f"{self.session_id}.jsonl"
        path.write_text("".join(json.dumps(record) + "\n" for record in self.records))
        return path


def short_session(cwd, session_id, started_at, prompt, reply):
    transcript = ClaudeTranscript(cwd, session_id, started_at)
    transcript.user(prompt)
    transcript.text(reply)
    return transcript
