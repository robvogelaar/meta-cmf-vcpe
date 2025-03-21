#!/usr/bin/env python3

import os, sys, re

def read_log_and_change_timestamps(log_file_path, base_timestamp):
    # Read the content of the file
    with open(log_file_path, 'r', errors='ignore') as f:
        lines = f.readlines()

    # Extract the first timestamp as a reference
    pattern = r"(\d{6}-\d{2}:\d{2}:\d{2}\.\d{6})"
    reference_timestamp = None
    for line in lines:
        match = re.search(pattern, line)
        if match:
            reference_timestamp = base_timestamp
            break

    if not reference_timestamp:
        #print(log_file_path)
        #print("No valid timestamps found in the log.")
        return

    ref_time = convert_to_seconds(reference_timestamp)

    # Convert each timestamp to relative timestamp
    with open(log_file_path, 'w') as f:
        for line in lines:
            match = re.search(pattern, line)
            if match:
                current_time = convert_to_seconds(match.group(1))
                relative_time = current_time - ref_time
                relative_time_str = f"{relative_time:.6f}"
                f.write(line.replace(match.group(1), relative_time_str))
            else:
                f.write(line)

def convert_to_seconds(timestamp):
    day, rest = timestamp.split("-")
    hours, minutes, seconds = rest.split(":")
    seconds, microseconds = seconds.split(".")
    total_seconds = (int(day) * 86400) + (int(hours) * 3600) + (int(minutes) * 60) + int(seconds) + (int(microseconds) * 1e-6)
    return total_seconds


def find_lowest_timestamp(directory_path):
    pattern = r"(\d{6}-\d{2}:\d{2}:\d{2}\.\d{6})"

    lowest_timestamp = None

    # Iterate through all files in the directory
    for filename in os.listdir(directory_path):
        if filename == "combined_logs.txt.0":
            continue
        if filename == "Consolelog.txt.0":
            continue
        if filename == "lxd.txt.0":
            continue
        if filename.endswith(".txt.0"):
            file_path = os.path.join(directory_path, filename)
            #print(file_path)
            with open(file_path, 'r', errors='ignore') as f:
                for line in f:
                    #print(line)
                    match = re.search(pattern, line)
                    if match:
                        #print(line)
                        current_timestamp = match.group(1)
                        #print(current_timestamp)
                        # If no lowest_timestamp has been set or current timestamp is lower
                        if not lowest_timestamp or current_timestamp < lowest_timestamp:
                            lowest_timestamp = current_timestamp
                            #print('now lowest_timestamp: %s(%s)' %(lowest_timestamp, filename))
    return lowest_timestamp


def extract_lines_with_timestamps(file_path):
    """Extracts lines and their timestamps from a log file."""
    pattern = r"(\d{6}-\d{2}:\d{2}:\d{2}\.\d{6})"
    lines_with_timestamps = []

    with open(file_path, 'r', errors='ignore') as f:
        for line in f:
            match = re.search(pattern, line)
            if match:
                timestamp = match.group(1)
                lines_with_timestamps.append((timestamp, line))

    return lines_with_timestamps

def combine_log_files_in_order(directory_path, output_file_path):
    """Combines log files based on the order of timestamps."""
    all_lines = []

    # Iterate through all files in the directory
    for filename in os.listdir(directory_path):
        if filename == "Consolelog.txt.0":
            continue
        if filename == "lxd.txt.0":
            continue
        if filename.endswith(".txt.0"):
            file_path = os.path.join(directory_path, filename)
            lines_with_timestamps = extract_lines_with_timestamps(file_path)
            all_lines.extend(lines_with_timestamps)

    # Sort lines by timestamp
    all_lines.sort(key=lambda x: x[0])

    # Write sorted lines to the output file
    with open(os.path.join(sys.argv[1], output_file_path), 'w') as f:
        for _, line in all_lines:
            f.write(line)


def main():

    if len(sys.argv) != 2:
        print("Usage: python script_name.py <path_to_log_files>")
        return

    output_file = "./combined_logs.txt.0"
    combine_log_files_in_order(sys.argv[1], output_file)
    #print(f"Combined logs written to {output_file}")

    base_timestamp = find_lowest_timestamp(sys.argv[1])
    #print('base_timestamp=', base_timestamp)

    for filename in os.listdir(sys.argv[1]):
        if filename == "Consolelog.txt.0":
            continue
        if filename == "lxd.txt.0":
            continue
        if filename.endswith(".txt.0"):
            file_path = os.path.join(sys.argv[1], filename)

            read_log_and_change_timestamps(file_path, base_timestamp)
            #print(f"Processed {file_path} with relative timestamps.")

if __name__ == "__main__":
    main()
