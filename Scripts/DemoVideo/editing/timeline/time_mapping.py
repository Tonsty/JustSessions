"""Converts between a take's source time and a footage scene's output time, given its pieces at their speeds."""


def piece_spans(pieces):
    """Each piece as (source start, source end, speed, output start, output end), output measured from the scene start."""
    spans, output = [], 0.0
    for source_start, source_end, speed in pieces:
        length = (source_end - source_start) / speed
        spans.append((source_start, source_end, speed, output, output + length))
        output += length
    return spans


def scene_length(pieces):
    return piece_spans(pieces)[-1][4]


def output_time(pieces, source):
    """Where a source moment lands in the scene; moments cut out snap to the nearest kept edge."""
    spans = piece_spans(pieces)
    for source_start, source_end, speed, output_start, _ in spans:
        if source < source_start:
            return output_start
        if source <= source_end:
            return output_start + (source - source_start) / speed
    return spans[-1][4]


def source_time(pieces, output):
    for source_start, source_end, speed, output_start, output_end in piece_spans(pieces):
        if output <= output_end:
            return source_start + (max(output, output_start) - output_start) * speed
    return pieces[-1][1]


def is_kept(pieces, source):
    return any(source_start <= source <= source_end for source_start, source_end, _ in pieces)
