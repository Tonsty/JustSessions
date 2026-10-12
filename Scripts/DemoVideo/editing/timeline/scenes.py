"""The edit, scene by scene.

Footage scenes play pieces of a take, each at its own speed, so slow cursor travel goes by quickly while the
moments that matter play in real time. Times inside a footage scene are source times in that take, in seconds,
so cues line up with the driver log. Camera keys are (source time, center x, center y, zoom) in stage points
(1600x900); zoom 1 shows the whole stage. Voice cues are (line id, source time the line starts).
Card scenes have their own length; their voice cues are seconds from the scene start.
"""

SCENES = [
    {
        "name": "title",
        "card": "title",
        "duration": 3.0,
        "voice": [("s0-title", 0.2)],
    },
    {
        "name": "sidebar",
        "take": "A-sessions",
        "pieces": [(0.4, 3.9, 1.35)],
        "camera": [(0.4, 800, 450, 1.0), (1.7, 596, 365, 1.55)],
        "voice": [("s1-sidebar", 0.9)],
        "fade_in": 0.3,
    },
    {
        "name": "resume",
        "take": "A-sessions",
        "pieces": [(3.9, 6.2, 1.6), (6.2, 7.6, 1.3), (7.6, 9.2, 1.15)],
        "camera": [(3.9, 596, 365, 1.55), (4.7, 933, 300, 1.4), (7.6, 933, 300, 1.4), (8.4, 800, 450, 1.0)],
        "voice": [("s1-resume", 4.0)],
    },
    {
        "name": "agents",
        "take": "A-sessions",
        # Each double-click plays in real time; the cursor's trips between rows and OpenCode's start-up go fast.
        "pieces": [(9.2, 11.4, 2.6), (11.4, 12.4, 1.0), (12.4, 15.1, 2.7), (15.1, 15.5, 1.0), (15.5, 16.95, 2.8),
                   (16.95, 17.75, 1.0), (17.75, 18.9, 2.6), (18.9, 20.2, 1.0)],
        "camera": [(9.2, 800, 450, 1.0), (20.2, 800, 450, 1.08)],
        "voice": [("s1-codex", 11.8), ("s1-opencode", 17.05), ("s1-pi", 19.55)],
    },
    {
        "name": "search",
        "take": "B-search",
        "pieces": [(1.8, 3.15, 1.8), (3.15, 4.6, 1.0), (4.6, 7.15, 2.4), (7.15, 8.2, 1.0), (8.2, 11.0, 2.6),
                   (11.0, 12.1, 1.0)],
        "camera": [(1.8, 800, 450, 1.0), (2.8, 537, 330, 1.75), (7.15, 537, 330, 1.75), (7.6, 933, 330, 1.4),
                   (11.0, 933, 330, 1.4), (11.6, 800, 450, 1.1)],
        "voice": [("s2-search", 3.5), ("s2-resume", 9.6)],
    },
    {
        "name": "split",
        "take": "C-split",
        "pieces": [(1.5, 3.3, 1.8), (3.3, 4.7, 2.2), (4.7, 5.9, 1.25), (5.9, 7.35, 1.6), (7.35, 9.6, 1.0)],
        "camera": [(1.5, 914, 310, 1.45), (7.6, 914, 310, 1.45), (8.3, 800, 450, 1.0)],
        "voice": [("s3-tabs", 1.9), ("s3-split", 7.6)],
    },
    {
        "name": "window",
        "take": "D-window",
        "pieces": [(1.2, 3.55, 1.7), (3.55, 5.2, 1.0), (5.2, 7.0, 1.0)],
        "camera": [(1.2, 800, 450, 1.0), (7.0, 800, 450, 1.04)],
        "voice": [("s4-window", 2.2)],
    },
    {
        "name": "ssh",
        "take": "E-ssh",
        # The cut from 8.2 to 11.85 skips the idle prompt; the camera moves at the same moment, so it reads as an edit.
        "pieces": [(1.3, 3.5, 1.6), (3.5, 6.9, 1.7), (6.9, 8.2, 1.0), (11.85, 15.0, 1.7), (15.0, 18.3, 2.2),
                   (18.3, 19.6, 1.3), (19.6, 21.75, 1.25), (21.75, 25.6, 3.2), (25.6, 28.0, 1.0)],
        "camera": [
            (1.3, 613, 520, 1.5), (3.5, 613, 520, 1.5),       # the devbox group in the sidebar
            (4.2, 933, 250, 1.4), (6.9, 933, 250, 1.4),     # its conversation: "devbox", and Resume
            (7.6, 800, 330, 1.3), (8.2, 800, 330, 1.3),       # Claude Code running on the server
            (11.85, 895, 600, 1.5), (14.8, 895, 600, 1.5),    # typing at the prompt
            (15.3, 794, 490, 1.85), (18.3, 794, 490, 1.85),   # progress; stays above Claude Code's tmux hint
            (18.7, 700, 250, 1.5), (19.6, 700, 250, 1.5),     # the tab's close button
            (19.9, 800, 470, 1.8), (21.75, 800, 470, 1.8),    # the Keep running dialog
            (22.2, 800, 450, 1.05), (25.6, 800, 450, 1.05),   # back to the list, click to reattach
            (26.2, 913, 580, 1.45),                           # the job kept going while the tab was closed
        ],
        "voice": [("s5-ssh", 1.5), ("s5-job", 12.2), ("s5-close", 18.4), ("s5-back", 25.3)],
        "fade_out": 0.35,
    },
    {
        "name": "end",
        "card": "end",
        "duration": 5.4,
        "voice": [("s6-end", 0.3)],
    },
]
