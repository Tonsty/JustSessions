"""A local stand-in for an OpenAI-compatible model, used only to give demo CLIs sample session history.

Serves canned replies over the Responses API (Codex) and Chat Completions (OpenCode, Pi). Listens on 127.0.0.1 only.
Each reply is picked by a keyword in the prompt, so fixtures/other_cli_sessions.sh's prompts decide what is said.

Usage: canned_model_server.py <port>
"""
import json
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MODEL = "gpt-5.5"

CANNED_REPLIES = [
    ("settings", "Split `SettingsPage` into `AccountSection`, `AppearanceSection`, and `NotificationsSection`. "
                 "Each section owns its own form state now, and the page is down from 410 to 96 lines. "
                 "Type check and the settings tests pass."),
    ("postgres", "Moved the migrations to Postgres 17. `jsonb_path_query` replaces the old helper, "
                 "and the two slow reports now use the new incremental sort. All 84 API tests pass."),
    ("e2e", "Added Playwright tests for sign-in: password, magic link, and a locked account. "
            "They run in 11 seconds and pass locally."),
    ("readme", "Updated the README: new install steps, a section on environment variables, "
               "and fresh screenshots of the dashboard."),
]


def reply_for(prompt_text):
    lowered = prompt_text.lower()
    for keyword, reply in CANNED_REPLIES:
        if keyword in lowered:
            return reply
    return "Done. The change is in place and the tests pass."


def chunks(text, size=12):
    words = text.split(" ")
    for index in range(0, len(words), size):
        yield " ".join(words[index:index + size]) + (" " if index + size < len(words) else "")


def last_user_text_from_responses(body):
    texts = []
    for item in body.get("input", []) if isinstance(body.get("input"), list) else []:
        if item.get("role") == "user":
            for part in item.get("content", []):
                if isinstance(part, dict) and part.get("type") == "input_text":
                    texts.append(part.get("text", ""))
    candidates = [text for text in texts if not text.lstrip().startswith("<")]
    return candidates[-1] if candidates else (texts[-1] if texts else "")


def last_user_text_from_chat(body):
    for message in reversed(body.get("messages", [])):
        if message.get("role") == "user":
            content = message.get("content")
            if isinstance(content, list):
                return " ".join(part.get("text", "") for part in content if isinstance(part, dict))
            return content or ""
    return ""


class CannedModelHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format_string, *arguments):
        sys.stderr.write("%s %s\n" % (self.command, self.path))

    def send_json(self, payload, status=200):
        data = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def start_stream(self):
        self.send_response(200)
        self.send_header("Content-Type", "text/event-stream")
        self.send_header("Cache-Control", "no-cache")
        self.send_header("Connection", "close")
        self.end_headers()
        self.close_connection = True

    def send_event(self, payload, event_name=None):
        line = (f"event: {event_name}\n" if event_name else "") + f"data: {json.dumps(payload)}\n\n"
        self.wfile.write(line.encode())
        self.wfile.flush()

    def do_GET(self):
        if self.path.rstrip("/").endswith("/models"):
            self.send_json({"object": "list", "data": [{"id": MODEL, "object": "model", "owned_by": "demo"}],
                            "models": [{"slug": MODEL, "display_name": "GPT-5.5"}]})
        else:
            self.send_json({"error": "not found"}, 404)

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        body = json.loads(self.rfile.read(length) or b"{}")
        if self.path.endswith("/responses"):
            self.stream_response(reply_for(last_user_text_from_responses(body)))
        elif self.path.endswith("/chat/completions"):
            self.stream_chat(reply_for(last_user_text_from_chat(body)), body.get("model", MODEL))
        else:
            self.send_json({"error": "not found"}, 404)

    def stream_response(self, text):
        created = int(time.time())
        response = {"id": "resp_demo", "object": "response", "created_at": created, "status": "in_progress",
                    "model": MODEL, "output": []}
        item = {"id": "msg_demo", "type": "message", "status": "in_progress", "role": "assistant", "content": []}
        self.start_stream()
        self.send_event({"type": "response.created", "response": response}, "response.created")
        self.send_event({"type": "response.in_progress", "response": response}, "response.in_progress")
        self.send_event({"type": "response.output_item.added", "output_index": 0, "item": item},
                        "response.output_item.added")
        self.send_event({"type": "response.content_part.added", "item_id": "msg_demo", "output_index": 0,
                         "content_index": 0, "part": {"type": "output_text", "text": "", "annotations": []}},
                        "response.content_part.added")
        for piece in chunks(text):
            self.send_event({"type": "response.output_text.delta", "item_id": "msg_demo", "output_index": 0,
                             "content_index": 0, "delta": piece}, "response.output_text.delta")
            time.sleep(0.02)
        part = {"type": "output_text", "text": text, "annotations": []}
        self.send_event({"type": "response.output_text.done", "item_id": "msg_demo", "output_index": 0,
                         "content_index": 0, "text": text}, "response.output_text.done")
        self.send_event({"type": "response.content_part.done", "item_id": "msg_demo", "output_index": 0,
                         "content_index": 0, "part": part}, "response.content_part.done")
        done_item = dict(item, status="completed", content=[part])
        self.send_event({"type": "response.output_item.done", "output_index": 0, "item": done_item},
                        "response.output_item.done")
        usage = {"input_tokens": 1800, "input_tokens_details": {"cached_tokens": 0}, "output_tokens": 90,
                 "output_tokens_details": {"reasoning_tokens": 0}, "total_tokens": 1890}
        self.send_event({"type": "response.completed",
                         "response": dict(response, status="completed", output=[done_item], usage=usage)},
                        "response.completed")

    def stream_chat(self, text, model):
        created = int(time.time())
        self.start_stream()
        first = True
        for piece in chunks(text):
            delta = {"role": "assistant", "content": piece} if first else {"content": piece}
            first = False
            self.send_event({"id": "chatcmpl-demo", "object": "chat.completion.chunk", "created": created,
                             "model": model, "choices": [{"index": 0, "delta": delta, "finish_reason": None}]})
            time.sleep(0.02)
        self.send_event({"id": "chatcmpl-demo", "object": "chat.completion.chunk", "created": created, "model": model,
                         "choices": [{"index": 0, "delta": {}, "finish_reason": "stop"}],
                         "usage": {"prompt_tokens": 1800, "completion_tokens": 90, "total_tokens": 1890}})
        self.wfile.write(b"data: [DONE]\n\n")
        self.wfile.flush()


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", int(sys.argv[1])), CannedModelHandler).serve_forever()
