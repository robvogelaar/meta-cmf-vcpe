#!/bin/env python3

import sys
import re
import random
import html
import colorsys

def generate_distinct_colors(n):
    colors = []
    for i in range(n):
        # Use golden ratio to space hues evenly
        hue = (i * 0.618033988749895) % 1
        # Use fixed saturation and value for pastel colors
        saturation = 0.3
        value = 0.95
        
        # Convert HSV to RGB
        rgb = colorsys.hsv_to_rgb(hue, saturation, value)
        # Convert to hex
        color = "#{:02x}{:02x}{:02x}".format(
            int(rgb[0] * 255),
            int(rgb[1] * 255),
            int(rgb[2] * 255)
        )
        colors.append(color)
    return colors

def process_log_file(filepath):
    modules = set()
    lines = []
    
    timestamp_pattern = r"^(\d+\.\d+)"
    module_pattern = r"\[mod=([^,]+)"
    level_pattern = r"lvl=([^\]]+)"
    thread_pattern = r"\[tid=(\d+)\]"
    
    with open(filepath, 'r') as f:
        for line in f:
            timestamp_match = re.search(timestamp_pattern, line)
            module_match = re.search(module_pattern, line)
            level_match = re.search(level_pattern, line)
            thread_match = re.search(thread_pattern, line)
            
            if all([timestamp_match, module_match, level_match, thread_match]):
                timestamp = timestamp_match.group(1)
                module = module_match.group(1)
                level = level_match.group(1)
                thread = thread_match.group(1)
                message = line.split(']', 3)[-1].strip()
                
                modules.add(module)
                lines.append({
                    'timestamp': timestamp,
                    'module': module,
                    'level': level,
                    'thread': thread,
                    'message': message,
                    'raw': html.escape(line.strip())
                })
    
    return list(modules), lines

def generate_html(modules, lines, output_path):
    # Generate distinct colors for each module
    distinct_colors = generate_distinct_colors(len(modules))
    module_colors = dict(zip(sorted(modules), distinct_colors))
    
    html_content = """
<!DOCTYPE html>
<html>
<head>
    <style>
        body { 
            font-family: monospace; 
            margin: 20px; 
            overflow: hidden;
        }
        .controls { 
            position: sticky; 
            top: 0; 
            background: white; 
            padding: 10px; 
            border-bottom: 1px solid #ccc;
            z-index: 1000;
        }
        .log-table { 
            border-collapse: separate; 
            border-spacing: 0;
            width: 100%; 
            margin-top: 20px;
            table-layout: fixed;
        }
        .log-table th {
            position: sticky;
            top: 50px;
            background: white;
            z-index: 10;
            border: 1px solid #ddd;
        }
        .log-table td { 
            padding: 5px; 
            border: 1px solid #ddd;
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }
        .log-line { cursor: pointer; }
        .log-line:hover { filter: brightness(0.9); }
        .selected { outline: 2px solid #000; }
        .hidden { display: none; }
        button { 
            margin: 5px; 
            padding: 5px 10px; 
            cursor: pointer; 
        }
        .active { 
            background-color: #4CAF50; 
            color: white; 
        }
        .resizer {
            position: absolute;
            right: 0;
            top: 0;
            height: 100%;
            width: 5px;
            background: rgba(0, 0, 0, 0.5);
            cursor: col-resize;
            user-select: none;
            touch-action: none;
        }
        .header {
            position: relative;
            padding: 5px;
        }
        th .header {
            padding-right: 10px;
        }
        .table-container {
            overflow-x: auto;
            max-height: calc(100vh - 100px);
        }
    </style>
    <script>
        function toggleModule(module) {
            const button = document.getElementById('btn-' + module);
            button.classList.toggle('active');
            
            const rows = document.getElementsByClassName('module-' + module);
            for (let row of rows) {
                row.classList.toggle('hidden');
            }
        }
        
        function toggleSelection(element) {
            element.classList.toggle('selected');
        }

        function createResizableColumn(th) {
            const resizer = document.createElement('div');
            resizer.classList.add('resizer');
            th.appendChild(resizer);
            let x = 0;
            let w = 0;

            const mouseDownHandler = function(e) {
                x = e.clientX;
                const styles = window.getComputedStyle(th);
                w = parseInt(styles.width, 10);

                document.addEventListener('mousemove', mouseMoveHandler);
                document.addEventListener('mouseup', mouseUpHandler);
                
                resizer.style.background = 'rgba(0, 0, 0, 0.8)';
            };

            const mouseMoveHandler = function(e) {
                const dx = e.clientX - x;
                th.style.width = `${w + dx}px`;
            };

            const mouseUpHandler = function() {
                document.removeEventListener('mousemove', mouseMoveHandler);
                document.removeEventListener('mouseup', mouseUpHandler);
                resizer.style.background = 'rgba(0, 0, 0, 0.5)';
            };

            resizer.addEventListener('mousedown', mouseDownHandler);
        }

        // Initialize resizable columns after the page loads
        document.addEventListener('DOMContentLoaded', function() {
            const columns = document.querySelectorAll('th');
            columns.forEach(createResizableColumn);
        });
    </script>
</head>
<body>
    <div class="controls">
    """
    
    # Add module toggle buttons
    for module in sorted(modules):
        html_content += f'<button id="btn-{module}" class="active" onclick="toggleModule(\'{module}\')">{module}</button>\n'
    
    html_content += """
    </div>
    <div class="table-container">
        <table class="log-table">
            <tr>
                <th style="width: 100px;"><div class="header">Timestamp</div></th>
                <th style="width: 200px;"><div class="header">Module/Level</div></th>
                <th style="width: 100px;"><div class="header">Thread</div></th>
                <th><div class="header">Message</div></th>
            </tr>
    """
    
    # Add log lines
    for line in lines:
        bg_color = module_colors[line['module']]
        html_content += f"""
        <tr class="log-line module-{line['module']}" onclick="toggleSelection(this)" style="background-color: {bg_color}">
            <td>{line['timestamp']}</td>
            <td>[mod={line['module']}, lvl={line['level']}]</td>
            <td>[tid={line['thread']}]</td>
            <td>{line['message']}</td>
        </tr>
        """
    
    html_content += """
        </table>
    </div>
</body>
</html>
    """
    
    with open(output_path, 'w') as f:
        f.write(html_content)

def main():
    if len(sys.argv) != 2:
        print("Usage: python script.py <log_file_path>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_file = input_file + '.html'
    
    modules, lines = process_log_file(input_file)
    generate_html(modules, lines, output_file)
    #print(f"HTML file generated: {output_file}")

if __name__ == "__main__":
    main()