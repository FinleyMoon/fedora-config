import argparse
import re
from datetime import datetime, timedelta

def offset_subtitles(srt_file, offset_seconds):
    """Offsets the timestamps in an SRT file by a given number of seconds.

    Args:
        srt_file (str): Path to the SRT file.
        offset_seconds (float): The number of seconds to offset the timestamps.
                                Positive values delay the subtitles, negative values
                                advance them.
    """

    def parse_timestamp(timestamp):
        """Parses an SRT timestamp into a datetime object."""
        return datetime.strptime(timestamp, '%H:%M:%S,%f')

    def format_timestamp(dt):
        """Formats a datetime object into an SRT timestamp."""
        return dt.strftime('%H:%M:%S,%f')[:-3]  # Remove microseconds

    with open(srt_file, 'r') as f:
        lines = f.readlines()

    new_lines = []
    for line in lines:
        if ' --> ' in line:
            start, end = line.strip().split(' --> ')
            start_dt = parse_timestamp(start)
            end_dt = parse_timestamp(end)

            offset = timedelta(seconds=offset_seconds)
            new_start = format_timestamp(start_dt + offset)
            new_end = format_timestamp(end_dt + offset)

            new_line = f'{new_start} --> {new_end}\n'
        else:
            new_line = line
        new_lines.append(new_line)

    with open(srt_file[:-4] + '_offset.srt', 'w') as f:
        f.writelines(new_lines)

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Offset subtitles in an SRT file.')
    parser.add_argument('srt_file', type=str, help='Path to the SRT file')
    parser.add_argument('offset_seconds', type=float, help='Offset in seconds (positive or negative)')
    args = parser.parse_args()

    offset_subtitles(args.srt_file, args.offset_seconds)
    print(f'Subtitles offset by {args.offset_seconds} seconds. New file saved as {args.srt_file[:-4] + "_offset.srt"}')
