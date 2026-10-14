/// A raw-input CLI stand-in. Terminal initialization can deliver device-attribute replies before user keys: tmux passes
/// a reply that comes after it stopped waiting, 5 seconds after it attached, on to the pane, as when the main thread is
/// busy while a test opens the tab. Recognize those replies as a real terminal program does: `CSI ? … c`, `CSI > … c`,
/// and Ghostty's version (`DCS > | … ST`). Record every other byte unchanged, until `KEY_BYTE_COUNT` bytes, 8 unless set.
/// With `ASKS_FOR_EXTENDED_KEYS` set, first ask for keyboard modes as Codex does: modifyOtherKeys 2, which tmux takes,
/// and the kitty keyboard protocol, which tmux ignores. tmux then passes a late reply's Esc on as Option: `CSI ? … c`
/// arrives as Option-[ (`CSI 91;3u`) and `? … c`, and `DCS … ST` as Option-P (`CSI 80;3u`) up to Option-\ (`CSI 92;3u`).
enum TmuxKeyboardReaderFixture {
    static let script = #"""
        #!/usr/bin/python3
        import os
        import pathlib
        import time
        import tty

        tty.setraw(0)
        if os.environ.get("ASKS_FOR_EXTENDED_KEYS"):
            os.write(1, b"\x1b[>4;2m\x1b[>7u")
        byte_count = int(os.environ.get("KEY_BYTE_COUNT", "8"))
        key_log = pathlib.Path(os.environ["KEY_LOG"])
        key_log.write_bytes(b"")
        pathlib.Path(os.environ["READY_MARKER"]).write_text("")
        os.write(1, b"KEY_READER_READY")

        unread = bytearray()

        def read_byte():
            if unread:
                return bytes([unread.pop(0)])
            byte = os.read(0, 1)
            if not byte:
                raise SystemExit("terminal closed before the keys arrived")
            return byte

        def read_sequence():
            sequence = bytearray(read_byte())
            if sequence != b"\x1b":
                return bytes(sequence)
            sequence.extend(read_byte())
            if sequence == b"\x1bP":
                while not sequence.endswith(b"\x1b\\"):
                    sequence.extend(read_byte())
            elif sequence == b"\x1b[":
                while True:
                    sequence.extend(read_byte())
                    if 0x40 <= sequence[-1] <= 0x7e:
                        break
            return bytes(sequence)

        def is_terminal_reply(sequence):
            if sequence.startswith(b"\x1bP"):
                return True
            return sequence.startswith((b"\x1b[?", b"\x1b[>")) and sequence.endswith(b"c")

        def skipped_terminal_reply_sent_as_keys(sequence):
            if sequence == b"\x1b[91;3u":
                following = read_byte()
                if following in (b"?", b">"):
                    while read_byte() != b"c":
                        pass
                    return True
                unread[:0] = following
            elif sequence == b"\x1b[80;3u":
                while read_sequence() != b"\x1b[92;3u":
                    pass
                return True
            return False

        recorded = bytearray()
        while len(recorded) < byte_count:
            sequence = read_sequence()
            if is_terminal_reply(sequence) or skipped_terminal_reply_sent_as_keys(sequence):
                continue
            recorded.extend(sequence)
            key_log.write_bytes(recorded)

        time.sleep(60)
        """#
}
